# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
require "droppable_table"

# Set up the dummy Rails application for testing
ENV["RAILS_ENV"] = "test"
require File.expand_path("fixtures/dummy_app/config/environment", __dir__)
require "rails/test_help"

require "minitest/autorun"
