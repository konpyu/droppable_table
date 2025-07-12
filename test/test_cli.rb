# frozen_string_literal: true

require "test_helper"
require "open3"

class TestCLI < Minitest::Test
  def setup
    @original_dir = Dir.pwd
    @dummy_app_dir = File.join(__dir__, "fixtures", "dummy_app")
    @bin_path = File.expand_path("../bin/droppable_table", __dir__)
  end

  def teardown
    Dir.chdir(@original_dir)
    # Clean up any baseline files created during tests
    baseline_file = File.join(@dummy_app_dir, ".droppable_table_baseline.json")
    FileUtils.rm_f(baseline_file)
  end

  def test_analyze_command_default_output
    Dir.chdir(@dummy_app_dir)

    output, status = run_command("analyze")

    assert status.success?
    assert output.include?("DroppableTable Analysis Report")
    assert output.include?("Potentially droppable tables:")
    assert output.include?("abandoned_logs")
  end

  def test_analyze_command_json_output
    Dir.chdir(@dummy_app_dir)

    output, status = run_command("analyze --json")

    assert status.success?
    json = JSON.parse(output)
    assert json["droppable_tables"].include?("abandoned_logs")
    assert json["summary"]["total_tables"].positive?
  end

  def test_analyze_command_with_config
    Dir.chdir(@dummy_app_dir)

    # Use the existing config that excludes legacy_data
    output, status = run_command("analyze")

    assert status.success?
    assert output.include?("abandoned_logs")
    refute output.include?("legacy_data") # Should be excluded by config
  end

  def test_analyze_command_strict_mode_creates_baseline
    Dir.chdir(@dummy_app_dir)

    # Remove baseline file to test creation
    baseline_file = ".droppable_table_baseline.json"
    FileUtils.rm_f(baseline_file)

    output, status = run_command("analyze --strict")

    assert File.exist?(baseline_file)
    assert output.include?("Created baseline file:")

    # Exit code should be 1 if droppable tables exist
    refute status.success?
  end

  def test_analyze_command_strict_mode_with_existing_baseline
    Dir.chdir(@dummy_app_dir)

    # Create baseline with only abandoned_logs
    baseline_content = {
      "droppable_tables" => ["abandoned_logs"],
      "generated_at" => Time.now.iso8601
    }
    File.write(".droppable_table_baseline.json", JSON.pretty_generate(baseline_content))

    output, status = run_command("analyze --strict")

    # Should pass since no new droppable tables
    refute status.success? # Still exits 1 because droppable tables exist
    refute output.include?("ERROR: New droppable tables found")
  end

  def test_version_command
    output, status = run_command("version")

    assert status.success?
    assert output.include?("DroppableTable")
    assert output.include?(DroppableTable::VERSION)
  end

  def test_version_flag_short
    output, status = run_command("-v")

    assert status.success?
    assert output.include?("DroppableTable")
    assert output.include?(DroppableTable::VERSION)
  end

  def test_version_flag_long
    output, status = run_command("--version")

    assert status.success?
    assert output.include?("DroppableTable")
    assert output.include?(DroppableTable::VERSION)
  end

  def test_error_when_not_in_rails_directory
    Dir.chdir(@original_dir)

    output, status = run_command("analyze", error_expected: true)

    refute status.success?
    assert output.include?("ERROR:")
    assert output.include?("Schema not found")
  end

  def test_default_task_is_analyze
    Dir.chdir(@dummy_app_dir)

    # Running without any command should run analyze
    output, status = run_command("")

    assert status.success?
    assert output.include?("DroppableTable Analysis Report")
  end

  private

  def run_command(args, error_expected: false)
    env = { "RAILS_ENV" => "test" }
    cmd = "bundle exec #{@bin_path} #{args}".strip

    stdout, stderr, status = Open3.capture3(env, cmd)
    output = error_expected ? stderr : stdout

    [output, status]
  end
end
