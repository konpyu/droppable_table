# frozen_string_literal: true

module DroppableTable
  class Analyzer
    attr_reader :config, :schema_tables, :model_tables, :sti_base_tables,
                :habtm_tables, :droppable_tables, :excluded_tables

    def initialize(config = {})
      @config = config
      @schema_tables = {}      # DB name => array of table info
      @model_tables = Set.new  # Table names with corresponding models
      @sti_base_tables = Set.new  # STI base tables
      @habtm_tables = Set.new  # HABTM join tables
      @droppable_tables = []   # Potentially droppable tables
      @excluded_tables = load_excluded_tables # Rails internal + gems + user defined
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
      # TODO: Load from config files
      Set.new
    end

    def check_migration_status
      # TODO: Check for pending migrations
    end

    def detect_schema_format
      # TODO: Detect schema.rb or structure.sql
    end

    def collect_schema_tables
      # TODO: Parse schema files
    end

    def eager_load_models
      # TODO: Load all models
    end

    def collect_model_tables
      # TODO: Collect tables from models
    end

    def collect_sti_tables
      # TODO: Detect STI inheritance
    end

    def collect_habtm_tables
      # TODO: Detect HABTM join tables
    end

    def identify_droppable_tables
      # TODO: Identify droppable tables
    end

    def generate_json_report
      # TODO: Generate JSON report
      {}
    end

    def generate_text_report
      # TODO: Generate text report
      ''
    end
  end
end