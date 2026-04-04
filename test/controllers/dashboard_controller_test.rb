require "test_helper"

class DashboardControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in_as(users(:one))
  end

  test "shows projects list" do
    get root_url
    assert_response :success
    assert_select "h1", "Projects"
  end

  test "shows project with unresolved error count" do
    # myapp fixture already has 1 unresolved error group (nomethoderror)
    get root_url
    assert_response :success
    assert_select ".badge-danger", /1 unresolved/
  end

  test "shows all clear when no unresolved errors" do
    # otherapp has no error groups
    get root_url
    assert_response :success
    assert_select ".badge-success", /All clear/
  end

  test "redirects to login when not authenticated" do
    sign_out
    get root_url
    assert_response :redirect
  end
end
