# frozen_string_literal: true

namespace :db do
  desc "Inspect droppable tables that exist in schema.rb but have no corresponding ActiveRecord models"
  task inspect_droppable_table: :environment do
    Rails.application.eager_load!

    analyzer = DroppableTableAnalyzer.new
    analyzer.analyze
    analyzer.display_results
  end
end

class DroppableTableAnalyzer
  def initialize
    @schema_tables = {}
    @model_tables = Set.new
    @sti_base_tables = Set.new
    @polymorphic_tables = Set.new
    @habtm_tables = Set.new
    @droppable_tables = []
  end

  def analyze
    collect_schema_tables
    collect_model_tables
    collect_sti_tables
    collect_polymorphic_associations
    collect_habtm_tables
    identify_droppable_tables
  end

  def display_results
    puts "\n#{"=" * 80}"
    puts "Droppable Tables Analysis Report"
    puts "=" * 80

    if @droppable_tables.empty?
      puts "\nNo droppable tables found."
    else
      puts "\nPotentially droppable tables (#{@droppable_tables.size}):"
      puts "-" * 80

      @droppable_tables.each do |table_info|
        puts "\nTable: #{table_info[:name]}"
        puts "  Database: #{table_info[:database]}"
        puts "  Schema file: #{table_info[:schema_file]}"
      end
    end

    puts "\n#{"=" * 80}"
    puts "Summary:"
    puts "  Total tables in schemas: #{@schema_tables.values.flatten.size}"
    puts "  Tables with models: #{@model_tables.size}"
    puts "  STI base tables: #{@sti_base_tables.size}"
    puts "  HABTM join tables: #{@habtm_tables.size}"
    puts "  Potentially droppable: #{@droppable_tables.size}"
    puts "=" * 80
  end

  private

  def collect_schema_tables
    # Handle multiple databases
    ActiveRecord::Base.configurations.configs_for(env_name: Rails.env).each do |db_config|
      database_name = db_config.name
      schema_file = schema_file_for_database(database_name)

      next unless File.exist?(schema_file)

      tables = extract_tables_from_schema(schema_file)
      @schema_tables[database_name] = tables.map do |table|
        { name: table, database: database_name, schema_file: schema_file }
      end
    end
  end

  def schema_file_for_database(database_name)
    if database_name == "primary"
      Rails.root.join("db", "schema.rb")
    else
      Rails.root.join("db", "#{database_name}_schema.rb")
    end
  end

  def extract_tables_from_schema(schema_file)
    tables = []
    File.readlines(schema_file).each do |line|
      match = line.match(/^\s*create_table\s+"([^"]+)"/)
      tables << match[1] if match
    end
    tables
  end

  def collect_model_tables
    ActiveRecord::Base.descendants.each do |model|
      next if model.abstract_class?

      begin
        table_name = model.table_name
        @model_tables << table_name if table_name
      rescue StandardError
        # Skip models that can't determine their table name
      end
    end
  end

  def collect_sti_tables
    ActiveRecord::Base.descendants.each do |model|
      next if model.abstract_class?

      begin
        if model.column_names.include?("type") && model.superclass != ActiveRecord::Base
          parent = model.superclass
          while parent != ActiveRecord::Base && !parent.abstract_class?
            @sti_base_tables << parent.table_name
            parent = parent.superclass
          end
        end
      rescue StandardError
        # Skip models that can't be inspected
      end
    end
  end

  def collect_polymorphic_associations
    ActiveRecord::Base.descendants.each do |model|
      next if model.abstract_class?

      begin
        model.reflect_on_all_associations.each do |association|
          if association.polymorphic?
            # Polymorphic associations don't have their own tables
            # but we need to ensure the polymorphic type columns are considered
          end
        end
      rescue StandardError
        # Skip models that can't be inspected
      end
    end
  end

  def collect_habtm_tables
    ActiveRecord::Base.descendants.each do |model|
      next if model.abstract_class?

      begin
        model.reflect_on_all_associations(:has_and_belongs_to_many).each do |association|
          join_table = association.join_table
          @habtm_tables << join_table if join_table
        end
      rescue StandardError
        # Skip models that can't be inspected
      end
    end
  end

  def identify_droppable_tables
    @schema_tables.each_value do |tables|
      tables.each do |table_info|
        table_name = table_info[:name]

        # Skip if table has a model, is an STI base table, or is a HABTM join table
        next if @model_tables.include?(table_name)
        next if @sti_base_tables.include?(table_name)
        next if @habtm_tables.include?(table_name)

        # Skip Rails internal tables
        next if rails_internal_table?(table_name)

        @droppable_tables << table_info
      end
    end
  end

  def rails_internal_table?(table_name)
    %w[
      schema_migrations
      ar_internal_metadata
      active_storage_blobs
      active_storage_attachments
      active_storage_variant_records
    ].include?(table_name)
  end
end
