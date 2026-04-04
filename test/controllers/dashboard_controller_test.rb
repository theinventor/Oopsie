require "test_helper"

class DashboardControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in_as(users(:one))
  end

  test "homepage redirects authenticated users to projects" do
    get root_url
    assert_redirected_to projects_url
  end

  test "homepage is accessible when not authenticated" do
    sign_out
    get root_url
    assert_response :success
  end

  test "shows projects list" do
    get projects_url
    assert_response :success
    assert_select "h1", "Projects"
  end

  test "shows project with unresolved error count" do
    get projects_url
    assert_response :success
    assert_select ".badge-danger", /1 unresolved/
  end

  test "shows all clear when no unresolved errors" do
    get projects_url
    assert_response :success
    assert_select ".badge-success", /All clear/
  end

  test "projects list redirects to login when not authenticated" do
    sign_out
    get projects_url
    assert_response :redirect
  end
end
