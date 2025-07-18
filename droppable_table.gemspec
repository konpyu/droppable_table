# frozen_string_literal: true

require_relative "lib/droppable_table/version"

Gem::Specification.new do |spec|
  spec.name = "droppable_table"
  spec.version = DroppableTable::VERSION
  spec.authors = ["konpyu"]
  spec.email = ["konpyu@gmail.com"]

  spec.summary = "A gem to identify potentially droppable tables in Rails applications"
  spec.description = "Analyzes Rails schema files and ActiveRecord models to identify tables that exist in " \
                     "schema but have no corresponding models, helping with database cleanup."
  spec.homepage = "https://github.com/konpyu/droppable_table"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.0.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/konpyu/droppable_table"
  spec.metadata["changelog_uri"] = "https://github.com/konpyu/droppable_table/blob/main/CHANGELOG.md"
  spec.metadata["rubygems_mfa_required"] = "true"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  gemspec = File.basename(__FILE__)
  spec.files = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
    ls.readlines("\x0", chomp: true).reject do |f|
      (f == gemspec) ||
        f.start_with?(*%w[test/ spec/ features/ .git .github appveyor Gemfile])
    end
  end
  spec.bindir = "bin"
  spec.executables = ["droppable_table"]
  spec.require_paths = ["lib"]

  # Dependencies
  spec.add_dependency "railties", ">= 6.0"
  spec.add_dependency "thor", "~> 1.0"

  # Development dependencies
  spec.add_development_dependency "minitest", "~> 5.0"
  spec.add_development_dependency "rails", ">= 6.0"
  spec.add_development_dependency "sqlite3", ">= 1.4"

  # For more information and examples about making a new gem, check out our
  # guide at: https://bundler.io/guides/creating_gem.html
end
