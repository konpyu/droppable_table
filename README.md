# DroppableTable

[![Gem Version](https://badge.fury.io/rb/droppable_table.svg)](https://badge.fury.io/rb/droppable_table)
[![Ruby](https://github.com/konpyu/droppable_table/actions/workflows/main.yml/badge.svg)](https://github.com/konpyu/droppable_table/actions/workflows/main.yml)

A Ruby gem that helps identify potentially droppable tables in Rails applications by analyzing schema files and ActiveRecord models. It finds tables that exist in your database schema but have no corresponding models, helping with database cleanup and maintenance.

## Features

- 🔍 Detects tables without corresponding ActiveRecord models
- 🚀 Supports multiple databases (primary, secondary, etc.)
- 🎯 Recognizes STI (Single Table Inheritance) tables
- 🔗 Identifies HABTM (has_and_belongs_to_many) join tables
- ⚙️ Configurable exclusion lists for tables and gems
- 📊 Multiple output formats (text and JSON)
- 🔒 Strict mode for CI integration

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'droppable_table'
```

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install droppable_table

## Usage

### Basic Usage

From your Rails application root directory:

```bash
# Analyze and show results
bundle exec droppable_table analyze

# Output in JSON format
bundle exec droppable_table analyze --json

# Use custom configuration file
bundle exec droppable_table analyze --config custom_config.yml
```

### Configuration

Create a `droppable_table.yml` file in your Rails root:

```yaml
# Tables to exclude from the droppable list
excluded_tables:
  - legacy_payments    # Keep for audit trail
  - archived_data      # Historical data
  - temp_migration     # Temporary migration table

# Exclude tables from specific gems
excluded_gems:
  - papertrail         # Exclude papertrail's versions table
  - delayed_job        # Exclude delayed_jobs table

# Strict mode for CI
strict_mode:
  enabled: true
  baseline_file: .droppable_table_baseline.json
```

### Strict Mode (CI Integration)

Strict mode helps prevent accidental table additions:

```bash
# First run creates a baseline
bundle exec droppable_table analyze --strict

# Subsequent runs will fail if new droppable tables are found
bundle exec droppable_table analyze --strict
```

### Example Output

```
DroppableTable Analysis Report
========================================

Summary:
  Total tables in schema: 25
  Tables with models: 20
  STI base tables: 2
  HABTM join tables: 3
  Excluded tables: 15
  Potentially droppable: 2

Potentially droppable tables:
  - abandoned_logs
  - legacy_sessions
```

## How It Works

1. **Schema Analysis**: Parses your `db/schema.rb` (or `structure.sql`) to find all tables
2. **Model Detection**: Loads all ActiveRecord models in your application
3. **Relationship Analysis**: 
   - Identifies STI base tables (won't be marked as droppable)
   - Detects HABTM join tables (won't be marked as droppable)
4. **Exclusion Processing**: Applies exclusion rules from configuration
5. **Report Generation**: Shows tables that exist in schema but have no models

## Built-in Exclusions

The gem automatically excludes:
- Rails internal tables (schema_migrations, ar_internal_metadata, etc.)
- Active Storage tables
- Action Text tables
- Common gem tables (when gems are listed in excluded_gems)

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/konpyu/droppable_table. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/konpyu/droppable_table/blob/main/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the DroppableTable project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/konpyu/droppable_table/blob/main/CODE_OF_CONDUCT.md).