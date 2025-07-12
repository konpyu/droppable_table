# frozen_string_literal: true

require "yaml"
require "pathname"

module DroppableTable
  class Config
    DEFAULT_CONFIG_FILE = "droppable_table.yml"
    RAILS_INTERNAL_TABLES_FILE = File.expand_path("../../config/rails_internal_tables.yml", __dir__)
    KNOWN_GEMS_FILE = File.expand_path("../../config/known_gems.yml", __dir__)

    attr_reader :excluded_tables, :excluded_gems, :strict_mode, :config_file_path

    def initialize(config_file_path = nil)
      @config_file_path = config_file_path || DEFAULT_CONFIG_FILE
      @excluded_tables = Set.new
      @excluded_gems = Set.new
      @strict_mode = {}

      load_default_config
      load_user_config if File.exist?(@config_file_path)
    end

    def rails_internal_tables
      @rails_internal_tables ||= load_yaml_file(RAILS_INTERNAL_TABLES_FILE)
    end

    def known_gem_tables
      @known_gem_tables ||= load_yaml_file(KNOWN_GEMS_FILE)
    end

    def all_excluded_tables
      Set.new(excluded_tables) + Set.new(rails_internal_tables) + gem_excluded_tables
    end

    def strict_mode_enabled?
      strict_mode["enabled"] == true
    end

    def baseline_file
      strict_mode["baseline_file"] || ".droppable_table_baseline.json"
    end

    private

    def load_default_config
      @rails_internal_tables = load_yaml_file(RAILS_INTERNAL_TABLES_FILE) || []
      @known_gem_tables = load_yaml_file(KNOWN_GEMS_FILE) || {}
    end

    def load_user_config
      # TODO: Load user configuration from YAML file
      config = load_yaml_file(@config_file_path)
      return unless config && config.is_a?(Hash)

      @excluded_tables = Set.new(config["excluded_tables"] || [])
      @excluded_gems = Set.new(config["excluded_gems"] || [])
      @strict_mode = config["strict_mode"] || {}
    end

    def load_yaml_file(path)
      return [] unless File.exist?(path)

      YAML.load_file(path) || []
    rescue StandardError
      []
    end

    def gem_excluded_tables
      tables = Set.new

      excluded_gems.each do |gem_name|
        tables += known_gem_tables[gem_name] if known_gem_tables.is_a?(Hash) && known_gem_tables[gem_name]
      end

      tables
    end
  end
end
