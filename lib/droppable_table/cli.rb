# frozen_string_literal: true

require "thor"
require "json"

module DroppableTable
  class CLI < Thor
    package_name "DroppableTable"

    desc "analyze", "Analyze Rails application for potentially droppable tables"
    option :json, type: :boolean, desc: "Output results in JSON format"
    option :config, type: :string, desc: "Path to configuration file"
    option :strict, type: :boolean, desc: "Strict mode for CI (fail if new droppable tables found)"
    def analyze
      # Load configuration
      config = Config.new(options[:config])

      # Run analysis
      analyzer = Analyzer.new(config)
      analyzer.analyze

      # Generate report
      if options[:json]
        puts JSON.pretty_generate(analyzer.report(format: :json))
      else
        puts analyzer.report(format: :text)
      end

      # Handle strict mode
      handle_strict_mode(analyzer, config) if options[:strict] && config.strict_mode_enabled?

      # Exit with appropriate code
      exit(analyzer.droppable_tables.empty? ? 0 : 1) if options[:strict]
    rescue RailsNotFoundError => e
      error_exit("Rails application not found: #{e.message}")
    rescue MigrationPendingError => e
      error_exit("Migration pending: #{e.message}")
    rescue SchemaNotFoundError => e
      error_exit("Schema not found: #{e.message}")
    rescue StandardError => e
      error_exit("Error: #{e.message}\n#{e.backtrace.first(5).join("\n")}")
    end

    desc "version", "Display version"
    def version
      puts "DroppableTable #{DroppableTable::VERSION}"
    end
    map %w[-v --version] => :version

    def self.exit_on_failure?
      true
    end

    default_task :analyze

    private

    def handle_strict_mode(analyzer, config)
      baseline_file = config.baseline_file
      current_droppable = analyzer.droppable_tables.sort

      if File.exist?(baseline_file)
        baseline = JSON.parse(File.read(baseline_file))["droppable_tables"] || []
        new_tables = current_droppable - baseline

        if new_tables.any?
          puts "\nERROR: New droppable tables found in strict mode:"
          new_tables.each { |table| puts "  - #{table}" }
          puts "\nTo update the baseline, run without --strict flag."
          exit(1)
        end
      else
        # Create baseline file
        File.write(baseline_file, JSON.pretty_generate({
                                                         droppable_tables: current_droppable,
                                                         generated_at: Time.now.iso8601
                                                       }))
        puts "\nCreated baseline file: #{baseline_file}"
      end
    end

    def error_exit(message)
      warn "ERROR: #{message}"
      exit(1)
    end
  end
end
