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
    assert json["occurrences"].is_a?(Array)
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
    patch resolve_api_v1_error_group_url(@error_group), headers: @headers
    assert_response :success

    @error_group.reload
    assert_equal "resolved", @error_group.status
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
end
