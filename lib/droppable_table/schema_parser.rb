# frozen_string_literal: true

module DroppableTable
  class SchemaParser
    attr_reader :schema_path, :format

    def initialize(schema_path)
      @schema_path = schema_path
      @format = detect_format
    end

    def parse
      case format
      when :ruby
        parse_ruby_schema
      when :sql
        parse_sql_schema
      else
        raise SchemaNotFoundError, "Unknown schema format: #{schema_path}"
      end
    end

    private

    def detect_format
      # TODO: Detect schema format based on file extension
      case File.basename(schema_path)
      when /\.rb$/
        :ruby
      when /\.sql$/
        :sql
      else
        nil
      end
    end

    def parse_ruby_schema
      # TODO: Parse schema.rb
      []
    end

    def parse_sql_schema
      # TODO: Parse structure.sql
      []
    end
  end
end