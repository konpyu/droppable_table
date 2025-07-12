# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

DroppableTable is a Ruby gem that analyzes Rails applications to identify potentially droppable database tables - tables that exist in the schema but have no corresponding ActiveRecord models. This helps with database cleanup and maintenance.

## Commands

### Development Setup
```bash
# Install dependencies
bundle install

# Run all tests
bundle exec rake test

# Run a specific test file
bundle exec ruby -Ilib:test test/test_analyzer.rb

# Run tests from dummy app directory (required for some tests)
cd test/fixtures/dummy_app && RAILS_ENV=test bundle exec ruby -I../../../lib:../../.. ../../../test/test_analyzer.rb

# Run linter
bundle exec rubocop

# Run linter with auto-correction
bundle exec rubocop -A

# Build the gem
gem build droppable_table.gemspec

# Install gem locally
gem install ./droppable_table-0.1.0.gem
```

### Testing the Gem
```bash
# From a Rails application directory
bundle exec droppable_table analyze
bundle exec droppable_table analyze --json
bundle exec droppable_table analyze --strict
bundle exec droppable_table version
```

## Architecture

### Core Components

1. **Analyzer** (`lib/droppable_table/analyzer.rb`)
   - Central orchestrator that coordinates the analysis process
   - Workflow: check migrations → detect schema format → collect schema tables → load models → identify droppable tables
   - Handles both text and JSON report generation
   - Manages multi-database support (primary, secondary databases)

2. **SchemaParser** (`lib/droppable_table/schema_parser.rb`)
   - Parses Rails schema files (`schema.rb` or `structure.sql`)
   - Currently implements Ruby schema parsing, SQL parsing is TODO
   - Returns array of table information

3. **ModelCollector** (`lib/droppable_table/model_collector.rb`)
   - Loads Rails environment and collects all ActiveRecord models
   - Detects STI (Single Table Inheritance) base tables
   - Identifies HABTM (has_and_belongs_to_many) join tables
   - Handles custom table names and multi-database models

4. **Config** (`lib/droppable_table/config.rb`)
   - Loads configuration from YAML files
   - Manages exclusion lists (Rails internal tables, gem tables, user-defined)
   - Handles strict mode settings for CI integration
   - Default configs in `config/rails_internal_tables.yml` and `config/known_gems.yml`

5. **CLI** (`lib/droppable_table/cli.rb`)
   - Thor-based command line interface
   - Commands: `analyze` (default), `version`
   - Handles output formatting, strict mode, and error reporting

### Key Design Decisions

- **Multi-database Support**: Detects and analyzes multiple schema files (e.g., `schema.rb`, `secondary_schema.rb`)
- **Exclusion System**: Three-tier exclusion (Rails internal, known gems, user-defined)
- **STI Awareness**: STI base tables are not considered droppable even if no direct model exists
- **HABTM Recognition**: Join tables are recognized and not marked as droppable
- **Test Environment**: Migration checks are skipped in test environment to avoid false positives

### Testing Infrastructure

The gem includes a full Rails dummy application in `test/fixtures/dummy_app/` with:
- Multiple databases (primary and secondary)
- STI models (Vehicle → Car)
- HABTM relationships (User ↔ Role)
- Custom table names (CustomTableModel)
- Orphaned tables for testing (abandoned_logs, legacy_data)

### Configuration

Users can create `droppable_table.yml` to:
- Exclude specific tables
- Exclude tables from specific gems
- Enable strict mode for CI (fails if new droppable tables are found)

### RuboCop Configuration

The project enforces Ruby style guidelines with some customizations:
- String style: double quotes
- Line length: 120 characters
- Method length: 30 lines (relaxed for complex analysis methods)
- Test files excluded from some metrics