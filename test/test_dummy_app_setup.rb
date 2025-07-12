# frozen_string_literal: true

require "test_helper"

class TestDummyAppSetup < Minitest::Test
  def test_rails_environment_loaded
    assert defined?(Rails), "Rails should be loaded"
    assert_equal "test", Rails.env
  end

  def test_database_connections
    assert ActiveRecord::Base.connection.present?, "Primary database connection should be established"

    # Test secondary database connection by checking if SecondaryBase can connect
    begin
      assert SecondaryBase.connection.present?, "Secondary database connection should be established"
    rescue StandardError => e
      flunk "Secondary database connection failed: #{e.message}"
    end
  end

  def test_schema_files_exist
    primary_schema = Rails.root.join("db", "schema.rb")
    secondary_schema = Rails.root.join("db", "secondary_schema.rb")

    assert File.exist?(primary_schema), "Primary schema.rb should exist"
    assert File.exist?(secondary_schema), "Secondary schema.rb should exist"
  end

  def test_models_loaded_correctly
    # Test abstract base models
    assert defined?(ApplicationRecord), "ApplicationRecord should be defined"
    assert defined?(SecondaryBase), "SecondaryBase should be defined"
    assert SecondaryBase.abstract_class?, "SecondaryBase should be abstract"

    # Test regular models
    assert defined?(User), "User model should be defined"
    assert defined?(Role), "Role model should be defined"
    assert defined?(Vehicle), "Vehicle model should be defined"
    assert defined?(Car), "Car model should be defined"
    assert defined?(CustomTableModel), "CustomTableModel should be defined"
    assert defined?(SecondaryUser), "SecondaryUser model should be defined"
  end

  def test_table_name_mappings
    assert_equal "users", User.table_name
    assert_equal "roles", Role.table_name
    assert_equal "vehicles", Vehicle.table_name
    assert_equal "vehicles", Car.table_name # STI shares parent table
    assert_equal "custom_named_table", CustomTableModel.table_name
    assert_equal "secondary_users", SecondaryUser.table_name
  end

  def test_sti_relationship
    assert Car.superclass == Vehicle, "Car should inherit from Vehicle"
    assert Vehicle.column_names.include?("type"), "Vehicle table should have type column for STI"
  end

  def test_habtm_relationship
    primary_tables = ActiveRecord::Base.connection.tables
    assert primary_tables.include?("roles_users"), "HABTM join table should exist"

    # Test the actual HABTM relationship
    assert User.reflect_on_association(:roles).present?, "User should have roles association"
    assert Role.reflect_on_association(:users).present?, "Role should have users association"
    assert_equal :has_and_belongs_to_many, User.reflect_on_association(:roles).macro
    assert_equal :has_and_belongs_to_many, Role.reflect_on_association(:users).macro
  end

  def test_orphaned_tables_exist
    primary_tables = ActiveRecord::Base.connection.tables

    assert primary_tables.include?("abandoned_logs"), "Orphaned abandoned_logs table should exist"
    assert primary_tables.include?("legacy_data"), "Orphaned legacy_data table should exist"
  end

  def test_rails_internal_tables_exist
    primary_tables = ActiveRecord::Base.connection.tables

    assert primary_tables.include?("schema_migrations"), "schema_migrations should exist"
    assert primary_tables.include?("ar_internal_metadata"), "ar_internal_metadata should exist"
  end

  def test_secondary_database_tables
    secondary_tables = SecondaryBase.connection.tables

    assert secondary_tables.include?("secondary_users"), "secondary_users table should exist in secondary DB"
    assert secondary_tables.include?("schema_migrations"), "secondary schema_migrations should exist"
    assert secondary_tables.include?("ar_internal_metadata"), "secondary ar_internal_metadata should exist"
  end

  def test_eager_loading_works
    Rails.application.eager_load!
    assert true, "Eager loading completed successfully"
  rescue StandardError => e
    flunk "Eager loading failed: #{e.message}"
  end

  def test_activerecord_descendants_accessible
    # Ensure models are loaded
    Rails.application.eager_load!

    descendants = ActiveRecord::Base.descendants
    model_names = descendants.map(&:name)

    assert descendants.any? { |model| model.name == "User" }, "User should be in descendants. Found: #{model_names}"
    assert descendants.any? { |model| model.name == "Role" }, "Role should be in descendants. Found: #{model_names}"
    assert descendants.any? { |model|
      model.name == "Vehicle"
    }, "Vehicle should be in descendants. Found: #{model_names}"
    assert descendants.any? { |model| model.name == "Car" }, "Car should be in descendants. Found: #{model_names}"
    assert descendants.any? { |model|
      model.name == "CustomTableModel"
    }, "CustomTableModel should be in descendants. Found: #{model_names}"
    assert descendants.any? { |model|
      model.name == "SecondaryUser"
    }, "SecondaryUser should be in descendants. Found: #{model_names}"
  end
end
