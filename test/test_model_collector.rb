# frozen_string_literal: true

require "test_helper"

class TestModelCollector < Minitest::Test
  def setup
    # Change to dummy app directory for these tests
    @original_dir = Dir.pwd
    Dir.chdir(File.join(__dir__, "fixtures", "dummy_app"))
    
    # Set Rails env to test
    ENV["RAILS_ENV"] = "test"
    
    # Load Rails environment
    require File.join(Dir.pwd, "config", "environment")
  end

  def teardown
    Dir.chdir(@original_dir)
  end

  def test_collect_loads_models
    collector = DroppableTable::ModelCollector.new
    collector.collect

    assert collector.models.size > 0
    assert collector.table_mapping.size > 0
  end

  def test_table_names_returns_unique_set
    collector = DroppableTable::ModelCollector.new
    collector.collect

    table_names = collector.table_names
    assert_kind_of Set, table_names
    assert table_names.include?("users")
    assert table_names.include?("roles")
    assert table_names.include?("vehicles")
    assert table_names.include?("custom_named_table")
  end

  def test_sti_base_tables_detection
    collector = DroppableTable::ModelCollector.new
    collector.collect

    sti_tables = collector.sti_base_tables
    assert_kind_of Set, sti_tables
    assert sti_tables.include?("vehicles")
    refute sti_tables.include?("users") # Users don't use STI
  end

  def test_habtm_tables_detection
    collector = DroppableTable::ModelCollector.new
    collector.collect

    habtm_tables = collector.habtm_tables
    assert_kind_of Set, habtm_tables
    assert habtm_tables.include?("roles_users")
  end

  def test_skips_abstract_classes
    collector = DroppableTable::ModelCollector.new
    collector.collect

    # SecondaryBase is abstract, shouldn't be in models list
    refute collector.models.include?(SecondaryBase)
    refute collector.table_mapping.keys.include?(SecondaryBase)
  end

  def test_handles_custom_table_names
    collector = DroppableTable::ModelCollector.new
    collector.collect

    # CustomTableModel uses custom table name
    assert collector.table_mapping[CustomTableModel] == "custom_named_table"
    assert collector.table_names.include?("custom_named_table")
  end

  def test_raises_error_without_rails
    # Save original Rails constant
    rails_const = Rails if defined?(Rails)
    
    # Temporarily remove Rails
    Object.send(:remove_const, :Rails) if defined?(Rails)
    
    # Create new collector in a different directory
    Dir.chdir(@original_dir) do
      collector = DroppableTable::ModelCollector.new
      
      assert_raises(DroppableTable::RailsNotFoundError) do
        collector.send(:ensure_rails_loaded)
      end
    end
  ensure
    # Restore Rails constant if it existed
    Object.const_set(:Rails, rails_const) if rails_const
  end
end