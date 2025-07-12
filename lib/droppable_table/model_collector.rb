# frozen_string_literal: true

require 'set'

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
      # TODO: Collect STI base tables
      Set.new
    end

    def habtm_tables
      # TODO: Collect HABTM join tables
      Set.new
    end

    private

    def ensure_rails_loaded
      # TODO: Ensure Rails is loaded
      raise RailsNotFoundError unless defined?(Rails)
    end

    def eager_load_all_models
      # TODO: Load all models
      Rails.application.eager_load! if defined?(Rails)
    end

    def collect_all_descendants
      # TODO: Collect all ActiveRecord descendants
      @models = ActiveRecord::Base.descendants if defined?(ActiveRecord::Base)
    end

    def build_table_mapping
      # TODO: Build model to table mapping
      models.each do |model|
        next if model.abstract_class?
        table_name = resolve_table_name(model)
        @table_mapping[model] = table_name if table_name
      rescue => e
        # Log error and continue
      end
    end

    def resolve_table_name(model)
      # TODO: Resolve actual table name considering custom names, prefixes, suffixes
      model.table_name
    rescue
      nil
    end
  end
end