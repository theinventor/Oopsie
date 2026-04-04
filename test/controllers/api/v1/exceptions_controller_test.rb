require "test_helper"

class Api::V1::ExceptionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @project = projects(:myapp)
    @headers = { "Authorization" => "Bearer #{@project.api_key}", "Content-Type" => "application/json" }
    @valid_payload = {
      notifier: "ExceptionReporter",
      version: "1.0.0",
      timestamp: "2026-04-04T14:23:45.892Z",
      app: { name: "MyApp", environment: "production" },
      error: {
        class_name: "NoMethodError",
        message: "undefined method 'downloads' for nil",
        backtrace: [ "app/controllers/designs_controller.rb:42:in 'show'" ],
        first_line: { file: "app/controllers/designs_controller.rb", line: 42, method: "show" },
        causes: [],
        handled: false
      },
      context: { action: "DesignsController#show" },
      server: { hostname: "web-1", pid: 12345, ruby_version: "4.0.2", rails_version: "8.1.3" }
    }
  end

  test "creates new error group and occurrence" do
    assert_difference [ "ErrorGroup.count", "Occurrence.count" ], 1 do
      post api_v1_exceptions_url, params: @valid_payload.to_json, headers: @headers
    end

    assert_response :created
    json = JSON.parse(response.body)
    assert json["id"].present?
    assert json["group_id"].present?
    assert_equal true, json["is_new_group"]
  end

  test "groups duplicate exceptions into same error group" do
    post api_v1_exceptions_url, params: @valid_payload.to_json, headers: @headers
    assert_response :created
    first_group_id = JSON.parse(response.body)["group_id"]

    assert_difference "Occurrence.count", 1 do
      assert_no_difference "ErrorGroup.count" do
        post api_v1_exceptions_url, params: @valid_payload.to_json, headers: @headers
      end
    end

    assert_response :created
    json = JSON.parse(response.body)
    assert_equal first_group_id, json["group_id"]
    assert_equal false, json["is_new_group"]
  end

  test "reopens resolved error group on new occurrence" do
    post api_v1_exceptions_url, params: @valid_payload.to_json, headers: @headers
    group = ErrorGroup.find(JSON.parse(response.body)["group_id"])
    group.update!(status: :resolved)

    post api_v1_exceptions_url, params: @valid_payload.to_json, headers: @headers
    assert_response :created

    group.reload
    assert_equal "unresolved", group.status
  end

  test "returns 401 without authorization header" do
    post api_v1_exceptions_url, params: @valid_payload.to_json,
      headers: { "Content-Type" => "application/json" }

    assert_response :unauthorized
    assert_equal "Invalid API key", JSON.parse(response.body)["error"]
  end

  test "returns 401 with invalid API key" do
    post api_v1_exceptions_url, params: @valid_payload.to_json,
      headers: { "Authorization" => "Bearer bad_key", "Content-Type" => "application/json" }

    assert_response :unauthorized
  end

  test "returns 429 when rate limit exceeded" do
    # Use memory store for this test since null_store can't track counts
    original_cache = Rails.cache
    Rails.cache = ActiveSupport::Cache::MemoryStore.new

    cache_key = "rate_limit:#{@project.id}:#{Time.current.to_i / 60}"
    Rails.cache.write(cache_key, 100, expires_in: 2.minutes)

    post api_v1_exceptions_url, params: @valid_payload.to_json, headers: @headers

    assert_response :too_many_requests
    assert_equal "Rate limit exceeded", JSON.parse(response.body)["error"]
  ensure
    Rails.cache = original_cache
  end

  test "stores occurrence details from payload" do
    post api_v1_exceptions_url, params: @valid_payload.to_json, headers: @headers
    assert_response :created

    occurrence = Occurrence.last
    assert_equal "undefined method 'downloads' for nil", occurrence.message
    assert_equal "production", occurrence.environment
    assert_equal false, occurrence.handled
    assert_equal "1.0.0", occurrence.notifier_version
    assert occurrence.backtrace.is_a?(Array)
    assert_equal "app/controllers/designs_controller.rb", occurrence.first_line["file"]
    assert_equal "web-1", occurrence.server_info["hostname"]
  end

  test "handles payload without first_line (fallback fingerprint)" do
    payload = @valid_payload.deep_dup
    payload[:error].delete(:first_line)

    assert_difference "ErrorGroup.count", 1 do
      post api_v1_exceptions_url, params: payload.to_json, headers: @headers
    end

    assert_response :created
  end

  test "increments occurrences_count via counter cache" do
    post api_v1_exceptions_url, params: @valid_payload.to_json, headers: @headers
    group_id = JSON.parse(response.body)["group_id"]

    post api_v1_exceptions_url, params: @valid_payload.to_json, headers: @headers
    post api_v1_exceptions_url, params: @valid_payload.to_json, headers: @headers

    assert_equal 3, ErrorGroup.find(group_id).occurrences_count
  end

  # --- 422 Unprocessable Entity tests ---

  test "returns 422 when error object is missing" do
    payload = { notifier: "ExceptionReporter", version: "1.0.0" }

    post api_v1_exceptions_url, params: payload.to_json, headers: @headers

    assert_response :unprocessable_entity
    json = JSON.parse(response.body)
    assert_equal "Unprocessable Entity", json["error"]
    assert_includes json["details"], "Missing error object"
  end

  test "returns 422 when error.class_name is missing" do
    payload = @valid_payload.deep_dup
    payload[:error].delete(:class_name)

    post api_v1_exceptions_url, params: payload.to_json, headers: @headers

    assert_response :unprocessable_entity
    json = JSON.parse(response.body)
    assert_includes json["details"], "Missing error.class_name"
  end

  test "returns 422 when error.class_name is blank" do
    payload = @valid_payload.deep_dup
    payload[:error][:class_name] = ""

    post api_v1_exceptions_url, params: payload.to_json, headers: @headers

    assert_response :unprocessable_entity
    json = JSON.parse(response.body)
    assert_includes json["details"], "Missing error.class_name"
  end

  test "returns 422 with empty body" do
    post api_v1_exceptions_url, params: "".to_json, headers: @headers

    assert_response :unprocessable_entity
  end
end
