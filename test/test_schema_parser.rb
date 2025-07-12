# frozen_string_literal: true

require "test_helper"
require "tempfile"

class TestSchemaParser < Minitest::Test
  def test_detects_ruby_format
    Tempfile.create(["schema", ".rb"]) do |file|
      parser = DroppableTable::SchemaParser.new(file.path)
      assert_equal :ruby, parser.format
    end
  end

  def test_detects_sql_format
    Tempfile.create(["structure", ".sql"]) do |file|
      parser = DroppableTable::SchemaParser.new(file.path)
      assert_equal :sql, parser.format
    end
  end

  def test_parse_ruby_schema_with_tables
    schema_content = <<~RUBY
      ActiveRecord::Schema[8.0].define(version: 2025_01_01_000000) do
        create_table "users", force: :cascade do |t|
          t.string "name"
          t.string "email"
        end

        create_table "posts", force: :cascade do |t|
          t.string "title"
          t.text "body"
        end
      end
    RUBY

    Tempfile.create(["schema", ".rb"]) do |file|
      file.write(schema_content)
      file.flush

      parser = DroppableTable::SchemaParser.new(file.path)
      tables = parser.parse

      assert_equal 2, tables.size
      assert_equal "users", tables[0][:name]
      assert_equal "table", tables[0][:type]
      assert_equal "posts", tables[1][:name]
      assert_equal "table", tables[1][:type]
    end
  end

  def test_parse_ruby_schema_empty_file
    Tempfile.create(["schema", ".rb"]) do |file|
      parser = DroppableTable::SchemaParser.new(file.path)
      tables = parser.parse

      assert_empty tables
    end
  end

  def test_parse_ruby_schema_nonexistent_file
    parser = DroppableTable::SchemaParser.new("/nonexistent/schema.rb")
    tables = parser.parse

    assert_empty tables
  end

  def test_parse_sql_schema_not_implemented
    Tempfile.create(["structure", ".sql"]) do |file|
      parser = DroppableTable::SchemaParser.new(file.path)
      tables = parser.parse

      assert_empty tables # Currently returns empty array (TODO)
    end
  end

  def test_parse_with_unknown_format
    parser = DroppableTable::SchemaParser.new("unknown.txt")

    assert_raises(DroppableTable::SchemaNotFoundError) do
      parser.parse
    end
  end
end
