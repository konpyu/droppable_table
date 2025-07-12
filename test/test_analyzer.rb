# frozen_string_literal: true

require "test_helper"

class TestAnalyzer < Minitest::Test
  def setup
    @original_dir = Dir.pwd
    Dir.chdir(File.join(__dir__, "fixtures", "dummy_app"))
    ENV["RAILS_ENV"] = "test"
    require File.join(Dir.pwd, "config", "environment")
  end

  def teardown
    Dir.chdir(@original_dir)
  end

  def test_analyze_full_workflow
    analyzer = DroppableTable::Analyzer.new
    analyzer.analyze

    # Should have detected schema tables
    assert analyzer.schema_tables.size.positive?
    assert analyzer.schema_tables["primary"].size.positive?

    # Should have collected model tables
    assert analyzer.model_tables.size.positive?
    assert analyzer.model_tables.include?("users")
    assert analyzer.model_tables.include?("roles")

    # Should have detected STI tables
    assert analyzer.sti_base_tables.include?("vehicles")

    # Should have detected HABTM tables
    assert analyzer.habtm_tables.include?("roles_users")

    # Should have identified droppable tables
    # Note: legacy_data is excluded in the config file
    assert analyzer.droppable_tables.include?("abandoned_logs")
    refute analyzer.droppable_tables.include?("legacy_data") # Excluded by config
  end

  def test_text_report_generation
    analyzer = DroppableTable::Analyzer.new
    analyzer.analyze

    report = analyzer.report(format: :text)

    assert report.include?("DroppableTable Analysis Report")
    assert report.include?("Total tables in schema:")
    assert report.include?("Potentially droppable tables:")
    assert report.include?("abandoned_logs")
  end

  def test_json_report_generation
    analyzer = DroppableTable::Analyzer.new
    analyzer.analyze

    report = analyzer.report(format: :json)

    assert report.is_a?(Hash)
    assert report[:summary][:total_tables].positive?
    assert report[:droppable_tables].include?("abandoned_logs")
    refute report[:droppable_tables].include?("legacy_data") # Excluded by config
    assert report[:model_tables].include?("users")
    assert report[:sti_base_tables].include?("vehicles")
    assert report[:habtm_tables].include?("roles_users")
  end

  def test_excludes_configured_tables
    # Test with the existing config that excludes legacy_data
    analyzer = DroppableTable::Analyzer.new
    analyzer.analyze

    # Should not include excluded table
    refute analyzer.droppable_tables.include?("legacy_data")
    # But should still include other droppable tables
    assert analyzer.droppable_tables.include?("abandoned_logs")

    # Test with a custom config that excludes abandoned_logs instead
    config_content = <<~YAML
      excluded_tables:
        - abandoned_logs
    YAML

    Tempfile.create(["droppable_table", ".yml"]) do |file|
      file.write(config_content)
      file.flush

      config = DroppableTable::Config.new(file.path)
      analyzer2 = DroppableTable::Analyzer.new(config)
      analyzer2.analyze

      # Should not include the newly excluded table
      refute analyzer2.droppable_tables.include?("abandoned_logs")
      # But should include legacy_data since it's not excluded in this config
      assert analyzer2.droppable_tables.include?("legacy_data")
    end
  end

  def test_excludes_rails_internal_tables
    analyzer = DroppableTable::Analyzer.new
    analyzer.analyze

    # Should never include Rails internal tables
    refute analyzer.droppable_tables.include?("schema_migrations")
    refute analyzer.droppable_tables.include?("ar_internal_metadata")
  end

  def test_handles_multiple_databases
    analyzer = DroppableTable::Analyzer.new
    analyzer.analyze

    # Should detect both primary and secondary schemas
    assert analyzer.schema_tables.key?("primary")
    assert analyzer.schema_tables.key?("secondary")
  end

  def test_raises_error_without_schema
    Dir.chdir(@original_dir)

    analyzer = DroppableTable::Analyzer.new

    assert_raises(DroppableTable::SchemaNotFoundError) do
      analyzer.analyze
    end
  end

  def test_check_migration_status_with_pending_migrations
    # Skip this test if migration_context is not available
    unless ActiveRecord::Base.connection.respond_to?(:migration_context)
      skip "migration_context not available in this Rails version"
    end

    # Mock pending migrations
    migration_context = Minitest::Mock.new
    migration_context.expect(:needs_migration?, true)

    ActiveRecord::Base.connection.stub(:migration_context, migration_context) do
      analyzer = DroppableTable::Analyzer.new

      assert_raises(DroppableTable::MigrationPendingError) do
        analyzer.send(:check_migration_status)
      end
    end
  end
end
