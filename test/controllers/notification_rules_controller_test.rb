require "test_helper"

class NotificationRulesControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in_as(users(:one))
    @project = projects(:myapp)
    @rule = notification_rules(:email_rule)
  end

  test "settings page shows API key" do
    get settings_project_url(@project)
    assert_response :success
    assert_select "code", /#{@project.api_key}/
  end

  test "settings page lists notification rules" do
    get settings_project_url(@project)
    assert_response :success
    assert_select "td code", "admin@example.com"
  end

  test "creates an email notification rule" do
    assert_difference "NotificationRule.count", 1 do
      post project_notification_rules_url(@project), params: {
        notification_rule: { channel: "email", destination: "dev@example.com" }
      }
    end
    assert_redirected_to settings_project_path(@project)
  end

  test "creates a webhook notification rule" do
    assert_difference "NotificationRule.count", 1 do
      post project_notification_rules_url(@project), params: {
        notification_rule: { channel: "webhook", destination: "https://hooks.slack.com/test" }
      }
    end
    assert_redirected_to settings_project_path(@project)
    assert_equal "webhook", NotificationRule.last.channel
  end

  test "rejects blank destination" do
    assert_no_difference "NotificationRule.count" do
      post project_notification_rules_url(@project), params: {
        notification_rule: { channel: "email", destination: "" }
      }
    end
    assert_response :unprocessable_entity
  end

  test "edits a notification rule" do
    get edit_project_notification_rule_url(@project, @rule)
    assert_response :success
    assert_select "form"
  end

  test "updates a notification rule" do
    patch project_notification_rule_url(@project, @rule), params: {
      notification_rule: { destination: "new@example.com" }
    }
    assert_redirected_to settings_project_path(@project)
    assert_equal "new@example.com", @rule.reload.destination
  end

  test "deletes a notification rule" do
    assert_difference "NotificationRule.count", -1 do
      delete project_notification_rule_url(@project, @rule)
    end
    assert_redirected_to settings_project_path(@project)
  end

  test "toggles a notification rule off" do
    assert @rule.enabled?
    patch toggle_project_notification_rule_url(@project, @rule)
    assert_redirected_to settings_project_path(@project)
    assert_not @rule.reload.enabled?
  end

  test "toggles a notification rule back on" do
    @rule.update!(enabled: false)
    patch toggle_project_notification_rule_url(@project, @rule)
    assert_redirected_to settings_project_path(@project)
    assert @rule.reload.enabled?
  end
end
