# frozen_string_literal: true

require_relative 'droppable_table/version'
require_relative 'droppable_table/cli'
require_relative 'droppable_table/analyzer'
require_relative 'droppable_table/schema_parser'
require_relative 'droppable_table/model_collector'
require_relative 'droppable_table/config'

module DroppableTable
  class Error < StandardError; end
  class RailsNotFoundError < Error; end
  class MigrationPendingError < Error; end
  class SchemaNotFoundError < Error; end
end
