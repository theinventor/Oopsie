require "test_helper"

class NotifyJobTest < ActiveJob::TestCase
  setup do
    @project = projects(:myapp)
    @error_group = @project.error_groups.create!(
      fingerprint: "notify_test_fp",
      error_class: "TestError",
      message: "test notification",
      status: :unresolved,
      first_seen_at: Time.current,
      last_seen_at: Time.current
    )
    @occurrence = @error_group.occurrences.create!(
      message: "test notification",
      occurred_at: Time.current,
      environment: "production"
    )
    @rule = notification_rules(:email_rule)
  end

  test "enqueues email for enabled email rule" do
    assert_enqueued_with(job: ActionMailer::MailDeliveryJob) do
      NotifyJob.perform_now(
        error_group_id: @error_group.id,
        occurrence_id: @occurrence.id,
        is_regression: false
      )
    end
  end

  test "enqueues webhook job for enabled webhook rule" do
    @rule.update!(channel: :webhook, destination: "https://hooks.example.com/test")

    assert_enqueued_with(job: WebhookDeliveryJob) do
      NotifyJob.perform_now(
        error_group_id: @error_group.id,
        occurrence_id: @occurrence.id,
        is_regression: false
      )
    end
  end

  test "skips disabled rules" do
    @rule.update!(enabled: false)

    assert_no_enqueued_jobs do
      NotifyJob.perform_now(
        error_group_id: @error_group.id,
        occurrence_id: @occurrence.id,
        is_regression: false
      )
    end
  end

  test "handles missing error group gracefully" do
    assert_nothing_raised do
      NotifyJob.perform_now(
        error_group_id: -1,
        occurrence_id: @occurrence.id,
        is_regression: false
      )
    end
  end
end
