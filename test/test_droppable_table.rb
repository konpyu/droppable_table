# frozen_string_literal: true

require "test_helper"

class TestDroppableTable < Minitest::Test
  def test_that_it_has_a_version_number
    refute_nil ::DroppableTable::VERSION
  end

  def test_gem_loads_successfully
    assert defined?(DroppableTable), "DroppableTable module should be defined"
  end
end
