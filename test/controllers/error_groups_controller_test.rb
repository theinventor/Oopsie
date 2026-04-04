require "test_helper"

class ErrorGroupsControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in_as(users(:one))
    @project = projects(:myapp)
    @error_group = error_groups(:nomethoderror)
  end

  test "shows error group detail page" do
    get project_error_group_url(@project, @error_group)
    assert_response :success
    assert_select "h1", /NoMethodError/
  end

  test "shows backtrace from latest occurrence" do
    get project_error_group_url(@project, @error_group)
    assert_response :success
    assert_select ".backtrace-frame"
  end

  test "shows occurrence timeline" do
    get project_error_group_url(@project, @error_group)
    assert_response :success
    assert_select ".error-table tbody tr"
  end

  test "shows stats (count, first seen, last seen)" do
    get project_error_group_url(@project, @error_group)
    assert_select ".stat-value", /3/  # occurrences_count
    assert_select ".stat-label", /Total occurrences/
  end

  test "resolves an error group" do
    patch resolve_project_error_group_url(@project, @error_group)
    assert_redirected_to project_error_group_path(@project, @error_group)
    assert_equal "resolved", @error_group.reload.status
  end

  test "ignores an error group" do
    patch ignore_project_error_group_url(@project, @error_group)
    assert_redirected_to project_error_group_path(@project, @error_group)
    assert_equal "ignored", @error_group.reload.status
  end

  test "unresolves a resolved error group" do
    @error_group.resolved!
    patch unresolve_project_error_group_url(@project, @error_group)
    assert_redirected_to project_error_group_path(@project, @error_group)
    assert_equal "unresolved", @error_group.reload.status
  end

  test "shows context and server info" do
    get project_error_group_url(@project, @error_group)
    assert_select ".context-json"
  end

  test "links back to project" do
    get project_error_group_url(@project, @error_group)
    assert_select "a[href=?]", project_path(@project), text: @project.name
  end
end
