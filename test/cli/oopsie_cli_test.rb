require "test_helper"
require "fileutils"
require "json"
require "open3"
require "tmpdir"

class OopsieCliTest < ActiveSupport::TestCase
  setup do
    @tmpdir = Dir.mktmpdir("oopsie-cli-test")
    @config_dir = File.join(@tmpdir, "config")
    @bin_dir = File.join(@tmpdir, "bin")
    @curl_log = File.join(@tmpdir, "curl.log")
    FileUtils.mkdir_p(@config_dir)
    FileUtils.mkdir_p(@bin_dir)

    File.write(File.join(@config_dir, "config.json"), JSON.generate(
      connections: {
        prod: {
          server: "http://oopsie.test",
          key: "user-key",
          project: { id: 7, name: "MyApp" }
        }
      },
      default: "prod"
    ))

    File.write(File.join(@bin_dir, "curl"), fake_curl_script)
    FileUtils.chmod(0o755, File.join(@bin_dir, "curl"))
  end

  teardown do
    FileUtils.remove_entry(@tmpdir) if @tmpdir && Dir.exist?(@tmpdir)
  end

  test "state command patches workflow state with note and provenance" do
    stdout, stderr, status = run_cli("state", "42", "in_progress", "--note", "Investigating cache miss.")

    assert status.success?, "stdout=#{stdout.inspect} stderr=#{stderr.inspect}"
    assert_includes stdout, "Set error group #42 workflow state to in_progress."

    args = curl_calls.last
    body = JSON.parse(value_after(args, "-d"))

    assert_equal "PATCH", value_after(args, "-X")
    assert_equal "http://oopsie.test/api/v1/error_groups/42/workflow_state", args.last
    assert_equal "in_progress", body["workflow_state"]
    assert_equal "Investigating cache miss.", body["note"]
    assert_includes headers_from(args), "X-Project-Id: 7"
    assert_includes headers_from(args), "X-Oopsie-Client: cli/oopsie 0.4.0"
  end

  test "note command posts plain note body" do
    stdout, stderr, status = run_cli("note", "42", "--body", "Confirmed nil user.")

    assert status.success?, "stdout=#{stdout.inspect} stderr=#{stderr.inspect}"
    assert_includes stdout, "Added note to error group #42."

    args = curl_calls.last
    body = JSON.parse(value_after(args, "-d"))

    assert_equal "POST", value_after(args, "-X")
    assert_equal "http://oopsie.test/api/v1/error_groups/42/notes", args.last
    assert_equal "Confirmed nil user.", body["body"]
  end

  test "errors command filters by workflow state and displays it" do
    stdout, stderr, status = run_cli("errors", "--workflow-state", "blocked")

    assert status.success?, "stdout=#{stdout.inspect} stderr=#{stderr.inspect}"
    assert_includes stdout, "[BLOCKED]"
    assert_includes stdout, "NoMethodError"
    assert_includes curl_calls.last.last, "workflow_state=blocked"
  end

  test "resolve command accepts note evidence" do
    stdout, stderr, status = run_cli("resolve", "42", "--note", "Fixed in deploy.")

    assert status.success?, "stdout=#{stdout.inspect} stderr=#{stderr.inspect}"
    assert_includes stdout, "Resolved error group #42."

    args = curl_calls.last
    body = JSON.parse(value_after(args, "-d"))

    assert_equal "PATCH", value_after(args, "-X")
    assert_equal "http://oopsie.test/api/v1/error_groups/42/resolve", args.last
    assert_equal "Fixed in deploy.", body["note"]
  end

  private

  def run_cli(*args)
    env = {
      "OOPSIE_CONFIG_DIR" => @config_dir,
      "CURL_LOG" => @curl_log,
      "PATH" => "#{@bin_dir}:#{ENV.fetch('PATH')}"
    }

    Open3.capture3(env, Rails.root.join("cli/oopsie").to_s, *args)
  end

  def curl_calls
    File.readlines(@curl_log).map { |line| JSON.parse(line) }
  end

  def value_after(args, flag)
    index = args.index(flag)
    args.fetch(index + 1)
  end

  def headers_from(args)
    args.each_cons(2).filter_map { |flag, value| value if flag == "-H" }
  end

  def fake_curl_script
    <<~RUBY
      #!/usr/bin/env ruby
      require "json"

      File.open(ENV.fetch("CURL_LOG"), "a") { |file| file.puts(JSON.generate(ARGV)) }

      method = ARGV[ARGV.index("-X") + 1]
      url = ARGV.last

      response =
        if method == "GET" && url.include?("/api/v1/error_groups?")
          {
            error_groups: [
              {
                id: 42,
                error_class: "NoMethodError",
                message: "undefined method",
                status: "unresolved",
                workflow_state: "blocked",
                occurrences_count: 3,
                first_seen_at: "2026-05-25T18:00:00Z",
                last_seen_at: "2026-05-25T19:00:00Z"
              }
            ],
            total: 1
          }
        elsif method == "POST" && url.end_with?("/notes")
          { note: { id: 9, kind: "note" }, error_group: { id: 42, workflow_state: "blocked" } }
        else
          { error_group: { id: 42, status: "unresolved", workflow_state: "in_progress" } }
        end

      puts JSON.generate(response)
      puts "200"
    RUBY
  end
end
