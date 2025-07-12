# frozen_string_literal: true

require "set"

module DroppableTable
  class ModelCollector
    attr_reader :models, :table_mapping

    def initialize
      @models = []
      @table_mapping = {} # model_class => table_name
    end

    def collect
      ensure_rails_loaded
      eager_load_all_models
      collect_all_descendants
      build_table_mapping

      self
    end

    def table_names
      Set.new(table_mapping.values)
    end

    def sti_base_tables
      sti_tables = Set.new

      models.each do |model|
        next if model.abstract_class?

        # Check if this model uses STI (has a 'type' column)
        sti_tables << model.table_name if model.columns_hash.key?("type") && model.base_class == model
      rescue StandardError
        # Skip models that can't be inspected
      end

      sti_tables
    end

    def habtm_tables
      habtm_join_tables = Set.new

      models.each do |model|
        next if model.abstract_class?

        # Find HABTM associations
        model.reflect_on_all_associations(:has_and_belongs_to_many).each do |association|
          join_table = association.join_table
          habtm_join_tables << join_table if join_table
        end
      rescue StandardError
        # Skip models that can't be inspected
      end

      habtm_join_tables
    end

    private

    def ensure_rails_loaded
      return if defined?(Rails)

      # Try to load Rails if we're in a Rails directory
      rails_path = File.join(Dir.pwd, "config", "environment.rb")
      unless File.exist?(rails_path)
        raise RailsNotFoundError, "Rails not found. Please run this command from a Rails application directory."
      end

      ENV["RAILS_ENV"] ||= "development"
      require rails_path
    end

    def eager_load_all_models
      return unless defined?(Rails)

      # Eager load the application to ensure all models are loaded
      Rails.application.eager_load!

      # Also load models from engines
      Rails::Engine.subclasses.each do |engine|
        engine.instance.eager_load!
      end
    end

    def collect_all_descendants
      return unless defined?(ActiveRecord::Base)

      # Collect all ActiveRecord descendants, excluding abstract classes
      @models = ActiveRecord::Base.descendants.reject(&:abstract_class?)
    end

    def build_table_mapping
      models.each do |model|
        next if model.abstract_class?

        begin
          # Check if model responds to table_name
          if model.respond_to?(:table_name)
            table_name = model.table_name
            @table_mapping[model] = table_name if table_name && !table_name.empty?
          end
        rescue StandardError
          # Skip models that raise errors when accessing table_name
          # This can happen with models that have database connection issues
        end
      end
    end

    def resolve_table_name(model)
      return nil unless model.respond_to?(:table_name)

      # Get the table name, considering custom configurations
      table_name = model.table_name

      # Apply any table name prefix/suffix if configured
      if model.respond_to?(:table_name_prefix) && model.table_name_prefix
        table_name = "#{model.table_name_prefix}#{table_name}"
      end

      if model.respond_to?(:table_name_suffix) && model.table_name_suffix
        table_name = "#{table_name}#{model.table_name_suffix}"
      end

      table_name
    rescue StandardError
      nil
    end
  end
end
