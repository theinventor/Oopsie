require "test_helper"

class Api::V1::ErrorGroupsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @project = projects(:myapp)
    @headers = { "Authorization" => "Bearer #{@project.api_key}", "Content-Type" => "application/json" }
    @error_group = error_groups(:nomethoderror)
    @resolved_group = error_groups(:resolved_error)
  end

  # --- Index ---

  test "lists error groups for the project" do
    get api_v1_error_groups_url, headers: @headers
    assert_response :success

    json = JSON.parse(response.body)
    assert json["error_groups"].is_a?(Array)
    assert json["total"].is_a?(Integer)
    assert json["error_groups"].length > 0
    assert_equal "untriaged", json["error_groups"].first["workflow_state"]
  end

  test "filters error groups by status" do
    get api_v1_error_groups_url, params: { status: "resolved" }, headers: @headers
    assert_response :success

    json = JSON.parse(response.body)
    json["error_groups"].each do |g|
      assert_equal "resolved", g["status"]
    end
  end

  test "returns empty array when no groups match status" do
    get api_v1_error_groups_url, params: { status: "ignored" }, headers: @headers
    assert_response :success

    json = JSON.parse(response.body)
    assert_equal 0, json["error_groups"].length
  end

  test "filters error groups by workflow state" do
    @error_group.set_workflow_state!(:blocked, actor: @project, source: "test")

    get api_v1_error_groups_url, params: { workflow_state: "blocked" }, headers: @headers
    assert_response :success

    json = JSON.parse(response.body)
    assert_equal [ @error_group.id ], json["error_groups"].map { |g| g["id"] }
    assert_equal "blocked", json["error_groups"].first["workflow_state"]
  end

  test "returns 422 for invalid workflow state filter" do
    get api_v1_error_groups_url, params: { workflow_state: "new" }, headers: @headers

    assert_response :unprocessable_entity
    assert_match "Invalid workflow state", JSON.parse(response.body)["error"]
  end

  test "returns 401 without auth" do
    get api_v1_error_groups_url
    assert_response :unauthorized
  end

  # --- Show ---

  test "shows error group with occurrences" do
    get api_v1_error_group_url(@error_group), headers: @headers
    assert_response :success

    json = JSON.parse(response.body)
    assert_equal @error_group.id, json["error_group"]["id"]
    assert_equal "NoMethodError", json["error_group"]["error_class"]
    assert_equal "untriaged", json["error_group"]["workflow_state"]
    assert json["occurrences"].is_a?(Array)
    assert json["activity"].is_a?(Array)
  end

  test "returns 404 for unknown error group" do
    get api_v1_error_group_url(id: 999999), headers: @headers
    assert_response :not_found
  end

  test "cannot see error groups from another project" do
    other_project = projects(:otherapp)
    other_headers = { "Authorization" => "Bearer #{other_project.api_key}", "Content-Type" => "application/json" }

    get api_v1_error_group_url(@error_group), headers: other_headers
    assert_response :not_found
  end

  # --- Resolve ---

  test "resolves an error group" do
    assert_difference "ErrorGroupNote.status_change.count", 1 do
      patch resolve_api_v1_error_group_url(@error_group),
        params: { note: "Fixed by deploy." }.to_json,
        headers: @headers
    end
    assert_response :success

    @error_group.reload
    assert_equal "resolved", @error_group.status
    assert_equal "untriaged", @error_group.workflow_state
    assert_equal "Fixed by deploy.", @error_group.error_group_notes.status_change.last.body
  end

  # --- Ignore ---

  test "ignores an error group" do
    patch ignore_api_v1_error_group_url(@error_group), headers: @headers
    assert_response :success

    @error_group.reload
    assert_equal "ignored", @error_group.status
  end

  # --- Unresolve ---

  test "unresolves a resolved error group" do
    patch unresolve_api_v1_error_group_url(@resolved_group), headers: @headers
    assert_response :success

    @resolved_group.reload
    assert_equal "unresolved", @resolved_group.status
  end

  test "updates workflow state without changing lifecycle status" do
    assert_difference "ErrorGroupNote.workflow_state_change.count", 1 do
      patch workflow_state_api_v1_error_group_url(@error_group),
        params: { workflow_state: "in_progress", note: "Agent is reproducing." }.to_json,
        headers: @headers.merge("X-Oopsie-Client" => "cli/oopsie test")
    end

    assert_response :success
    @error_group.reload
    note = @error_group.error_group_notes.workflow_state_change.last
    json = JSON.parse(response.body)

    assert_equal "unresolved", @error_group.status
    assert_equal "in_progress", @error_group.workflow_state
    assert_equal "in_progress", json["error_group"]["workflow_state"]
    assert_equal "Agent is reproducing.", note.body
    assert_equal "project", note.actor_kind
    assert_equal @project.name, note.actor_label
    assert_equal "cli/oopsie test", note.source
  end

  test "returns 404 when workflow update targets another project group" do
    other_project = projects(:otherapp)
    other_headers = { "Authorization" => "Bearer #{other_project.api_key}", "Content-Type" => "application/json" }

    patch workflow_state_api_v1_error_group_url(@error_group),
      params: { workflow_state: "looking" }.to_json,
      headers: other_headers

    assert_response :not_found
  end
end
