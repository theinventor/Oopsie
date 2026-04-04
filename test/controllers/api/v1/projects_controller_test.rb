require "test_helper"

class Api::V1::ProjectsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @project = projects(:myapp)
    @headers = { "Authorization" => "Bearer #{@project.api_key}", "Content-Type" => "application/json" }
  end

  test "shows project info" do
    get api_v1_project_url, headers: @headers
    assert_response :success

    json = JSON.parse(response.body)
    assert_equal @project.name, json["name"]
    assert_equal @project.id, json["id"]
    assert json.key?("error_groups_count")
    assert json.key?("unresolved_count")
    assert json.key?("created_at")
  end

  test "returns 401 without auth" do
    get api_v1_project_url
    assert_response :unauthorized
  end

  test "returns 401 with invalid key" do
    get api_v1_project_url, headers: { "Authorization" => "Bearer invalid", "Content-Type" => "application/json" }
    assert_response :unauthorized
  end
end
