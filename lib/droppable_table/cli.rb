# frozen_string_literal: true

require 'thor'

module DroppableTable
  class CLI < Thor
    package_name 'DroppableTable'

    desc 'analyze', 'Analyze Rails application for potentially droppable tables'
    option :json, type: :boolean, desc: 'Output results in JSON format'
    option :config, type: :string, desc: 'Path to configuration file'
    option :strict, type: :boolean, desc: 'Strict mode for CI (fail if new droppable tables found)'
    def analyze
      # TODO: Implement analyze logic
      puts 'Analyzing droppable tables...'
    end

    desc 'version', 'Display version'
    map %w[-v --version] => :version
    def version
      puts "DroppableTable #{VERSION}"
    end

    desc 'help', 'Display help'
    map %w[-h --help] => :help
    def help(command = nil)
      super
    end

    default_task :analyze
  end
end