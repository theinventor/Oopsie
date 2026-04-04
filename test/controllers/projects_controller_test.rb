require "test_helper"

class ProjectsControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in_as(users(:one))
    @project = projects(:myapp)
  end

  test "shows project detail page" do
    get project_url(@project)
    assert_response :success
    assert_select "h1", @project.name
  end

  test "shows project API key" do
    get project_url(@project)
    assert_select "code", @project.api_key
  end

  test "renders new project form" do
    get new_project_url
    assert_response :success
    assert_select "form"
  end

  test "creates a project" do
    assert_difference "Project.count", 1 do
      post projects_url, params: { project: { name: "New App" } }
    end
    assert_redirected_to root_path
    assert_equal "New App", Project.last.name
    assert Project.last.api_key.present?
  end

  test "rejects blank project name" do
    assert_no_difference "Project.count" do
      post projects_url, params: { project: { name: "" } }
    end
    assert_response :unprocessable_entity
  end

  test "updates a project" do
    patch project_url(@project), params: { project: { name: "Renamed" } }
    assert_redirected_to project_path(@project)
    assert_equal "Renamed", @project.reload.name
  end

  test "deletes a project" do
    assert_difference "Project.count", -1 do
      delete project_url(@project)
    end
    assert_redirected_to root_path
  end

  test "shows error groups on project page" do
    @project.error_groups.create!(
      fingerprint: "test123",
      error_class: "NoMethodError",
      message: "undefined method",
      status: :unresolved,
      first_seen_at: 1.hour.ago,
      last_seen_at: 1.minute.ago
    )

    get project_url(@project)
    assert_select ".error-class", "NoMethodError"
  end
end
