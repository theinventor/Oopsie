require "test_helper"

class OopsieMailerTest < ActionMailer::TestCase
  setup do
    @project = projects(:myapp)
    @error_group = @project.error_groups.create!(
      fingerprint: "mailer_test_fp",
      error_class: "RuntimeError",
      message: "something went wrong",
      status: :unresolved,
      first_seen_at: Time.current,
      last_seen_at: Time.current
    )
    @occurrence = @error_group.occurrences.create!(
      message: "something went wrong",
      backtrace: [ "app/models/user.rb:42:in 'load'", "app/controllers/users_controller.rb:10:in 'show'" ],
      environment: "production",
      occurred_at: Time.current
    )
    @rule = notification_rules(:email_rule)
  end

  test "sends new error notification" do
    email = OopsieMailer.error_notification(
      notification_rule: @rule,
      error_group: @error_group,
      occurrence: @occurrence,
      is_regression: false
    )

    assert_equal [ "admin@example.com" ], email.to
    assert_match "New: RuntimeError", email.subject
    assert_match @project.name, email.subject
    assert_match "RuntimeError", email.body.encoded
    assert_match "something went wrong", email.body.encoded
  end

  test "sends regression notification" do
    email = OopsieMailer.error_notification(
      notification_rule: @rule,
      error_group: @error_group,
      occurrence: @occurrence,
      is_regression: true
    )

    assert_match "Regression: RuntimeError", email.subject
  end

  test "includes backtrace in email" do
    email = OopsieMailer.error_notification(
      notification_rule: @rule,
      error_group: @error_group,
      occurrence: @occurrence,
      is_regression: false
    )

    assert_match "app/models/user.rb:42", email.body.encoded
  end
end
