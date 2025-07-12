# frozen_string_literal: true

require "set"
require "json"

module DroppableTable
  class Analyzer
    attr_reader :config, :schema_tables, :model_tables, :sti_base_tables,
                :habtm_tables, :droppable_tables, :excluded_tables

    def initialize(config = nil)
      @config = config.is_a?(Config) ? config : Config.new(config)
      @schema_tables = {}      # DB name => array of table info
      @model_tables = Set.new  # Table names with corresponding models
      @sti_base_tables = Set.new # STI base tables
      @habtm_tables = Set.new  # HABTM join tables
      @droppable_tables = []   # Potentially droppable tables
      @excluded_tables = @config.all_excluded_tables # Rails internal + gems + user defined
      @model_collector = nil
      @schema_format = nil
    end

    def analyze
      check_migration_status   # Check for pending migrations
      detect_schema_format     # Detect schema.rb vs structure.sql
      collect_schema_tables    # Collect tables from all schema files
      eager_load_models        # Ensure all models are loaded
      collect_model_tables     # Collect from ActiveRecord::Base.descendants
      collect_sti_tables       # Detect STI hierarchies
      collect_habtm_tables     # Detect HABTM associations
      identify_droppable_tables # Identify droppable tables

      self
    end

    def report(format: :text)
      # TODO: Implement report generation
      case format
      when :json
        generate_json_report
      else
        generate_text_report
      end
    end

    private

    def load_excluded_tables
      @config.all_excluded_tables
    end

    def check_migration_status
      # Skip migration check in test environment or if Rails/ActiveRecord not available
      return if ENV["RAILS_ENV"] == "test"
      return unless defined?(ActiveRecord::Base) && defined?(Rails)

      begin
        # Ensure database connection exists
        ActiveRecord::Base.connection

        # Try to check for pending migrations using available methods
        if ActiveRecord::Base.connection.respond_to?(:migration_context)
          # Rails 6.0+
          context = ActiveRecord::Base.connection.migration_context
          if context.needs_migration?
            raise MigrationPendingError, "There are pending migrations. Please run migrations before analyzing."
          end
        end
        # If migration check methods aren't available, skip the check
      rescue ActiveRecord::NoDatabaseError
        raise Error, "Database does not exist. Please create and migrate the database first."
      rescue StandardError
        # If any other error occurs during migration check, skip it
        # This ensures the tool remains functional even with different Rails versions
      end
    end

    def detect_schema_format
      schema_rb = File.join(Dir.pwd, "db", "schema.rb")
      structure_sql = File.join(Dir.pwd, "db", "structure.sql")

      if File.exist?(schema_rb)
        @schema_format = :ruby
      elsif File.exist?(structure_sql)
        @schema_format = :sql
      else
        raise SchemaNotFoundError, "No schema.rb or structure.sql found in db/ directory"
      end
    end

    def collect_schema_tables
      # Find all schema files (including from multiple databases)
      schema_files = find_schema_files

      schema_files.each do |schema_file|
        parser = SchemaParser.new(schema_file)
        tables = parser.parse

        # Determine database name from file path
        db_name = extract_database_name(schema_file)
        @schema_tables[db_name] = tables
      end
    end

    def find_schema_files
      files = []

      # Main schema file
      main_schema = File.join(Dir.pwd, "db", @schema_format == :sql ? "structure.sql" : "schema.rb")
      files << main_schema if File.exist?(main_schema)

      # Look for additional schema files (e.g., secondary_schema.rb)
      Dir.glob(File.join(Dir.pwd, "db", "*_schema.rb")).each do |file|
        files << file unless file == main_schema
      end

      files
    end

    def extract_database_name(schema_file)
      basename = File.basename(schema_file, ".*")

      case basename
      when "schema", "structure"
        "primary"
      else
        # Extract database name from filename like 'secondary_schema.rb'
        basename.sub(/_schema$/, "")
      end
    end

    def eager_load_models
      @model_collector = ModelCollector.new
      @model_collector.collect
    end

    def collect_model_tables
      return unless @model_collector

      @model_tables = @model_collector.table_names
    end

    def collect_sti_tables
      return unless @model_collector

      @sti_base_tables = @model_collector.sti_base_tables
    end

    def collect_habtm_tables
      return unless @model_collector

      @habtm_tables = @model_collector.habtm_tables
    end

    def identify_droppable_tables
      all_schema_tables = @schema_tables.values.flatten.to_set { |t| t[:name] }

      # Tables that exist in schema but have no corresponding model
      @droppable_tables = all_schema_tables.reject do |table|
        # Skip if table is excluded
        @excluded_tables.include?(table) ||
          # Skip if table has a model
          @model_tables.include?(table) ||
          # Skip if it's a HABTM join table
          @habtm_tables.include?(table) ||
          # Skip if it's an STI base table (these are important)
          @sti_base_tables.include?(table)
      end.to_a.sort
    end

    def generate_json_report
      {
        summary: {
          total_tables: @schema_tables.values.flatten.map { |t| t[:name] }.uniq.size,
          tables_with_models: @model_tables.size,
          sti_base_tables: @sti_base_tables.size,
          habtm_tables: @habtm_tables.size,
          excluded_tables: @excluded_tables.size,
          droppable_tables: @droppable_tables.size
        },
        droppable_tables: @droppable_tables,
        tables_by_database: @schema_tables.transform_values { |tables| tables.map { |t| t[:name] } },
        model_tables: @model_tables.to_a.sort,
        sti_base_tables: @sti_base_tables.to_a.sort,
        habtm_tables: @habtm_tables.to_a.sort,
        excluded_tables: @excluded_tables.to_a.sort
      }
    end

    def generate_text_report
      report = []
      report << "DroppableTable Analysis Report"
      report << ("=" * 40)
      report << ""

      # Summary
      all_tables = @schema_tables.values.flatten.map { |t| t[:name] }.uniq
      report << "Summary:"
      report << "  Total tables in schema: #{all_tables.size}"
      report << "  Tables with models: #{@model_tables.size}"
      report << "  STI base tables: #{@sti_base_tables.size}"
      report << "  HABTM join tables: #{@habtm_tables.size}"
      report << "  Excluded tables: #{@excluded_tables.size}"
      report << "  Potentially droppable: #{@droppable_tables.size}"
      report << ""

      # Droppable tables
      if @droppable_tables.empty?
        report << "No droppable tables found."
      else
        report << "Potentially droppable tables:"
        @droppable_tables.each do |table|
          report << "  - #{table}"
        end
      end
      report << ""

      # Tables by database
      if @schema_tables.size > 1
        report << "Tables by database:"
        @schema_tables.each do |db_name, tables|
          report << "  #{db_name}: #{tables.size} tables"
        end
        report << ""
      end

      report.join("\n")
    end
  end
end
