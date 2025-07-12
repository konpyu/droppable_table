# frozen_string_literal: true

require "test_helper"
require "tempfile"

class TestConfig < Minitest::Test
  def test_loads_default_rails_internal_tables
    config = DroppableTable::Config.new

    assert config.rails_internal_tables.include?("schema_migrations")
    assert config.rails_internal_tables.include?("ar_internal_metadata")
    assert config.rails_internal_tables.include?("active_storage_blobs")
  end

  def test_loads_known_gem_tables
    config = DroppableTable::Config.new

    assert config.known_gem_tables.is_a?(Hash)
    assert config.known_gem_tables["papertrail"].include?("versions")
    assert config.known_gem_tables["devise"].include?("users")
  end

  def test_loads_user_config_file
    config_content = <<~YAML
      excluded_tables:
        - custom_table1
        - custom_table2

      excluded_gems:
        - papertrail
        - delayed_job

      strict_mode:
        enabled: true
        baseline_file: custom_baseline.json
    YAML

    Tempfile.create(["droppable_table", ".yml"]) do |file|
      file.write(config_content)
      file.flush

      config = DroppableTable::Config.new(file.path)

      assert_equal Set.new(["custom_table1", "custom_table2"]), config.excluded_tables
      assert_equal Set.new(["papertrail", "delayed_job"]), config.excluded_gems
      assert config.strict_mode_enabled?
      assert_equal "custom_baseline.json", config.baseline_file
    end
  end

  def test_default_config_without_file
    config = DroppableTable::Config.new("/nonexistent/file.yml")

    assert_empty config.excluded_tables
    assert_empty config.excluded_gems
    refute config.strict_mode_enabled?
    assert_equal ".droppable_table_baseline.json", config.baseline_file
  end

  def test_all_excluded_tables_combines_sources
    config_content = <<~YAML
      excluded_tables:
        - my_custom_table

      excluded_gems:
        - papertrail
    YAML

    Tempfile.create(["droppable_table", ".yml"]) do |file|
      file.write(config_content)
      file.flush

      config = DroppableTable::Config.new(file.path)
      all_excluded = config.all_excluded_tables

      # Should include rails internal tables
      assert all_excluded.include?("schema_migrations")

      # Should include user excluded tables
      assert all_excluded.include?("my_custom_table")

      # Should include tables from excluded gems
      assert all_excluded.include?("versions") # from papertrail
    end
  end

  def test_gem_excluded_tables_builds_correctly
    config_content = <<~YAML
      excluded_gems:
        - papertrail
        - devise
    YAML

    Tempfile.create(["droppable_table", ".yml"]) do |file|
      file.write(config_content)
      file.flush

      config = DroppableTable::Config.new(file.path)
      gem_tables = config.send(:gem_excluded_tables)

      assert gem_tables.include?("versions") # from papertrail
      assert gem_tables.include?("version_associations") # from papertrail
      assert gem_tables.include?("users") # from devise
    end
  end

  def test_handles_malformed_yaml_gracefully
    config_content = "invalid: yaml: content: [["

    Tempfile.create(["droppable_table", ".yml"]) do |file|
      file.write(config_content)
      file.flush

      # Should not raise error, just use defaults
      config = DroppableTable::Config.new(file.path)
      assert_empty config.excluded_tables
      assert_empty config.excluded_gems
    end
  end
end
