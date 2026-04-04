require "test_helper"

class RetentionCleanupJobTest < ActiveJob::TestCase
  setup do
    @project = projects(:myapp)
    @error_group = @project.error_groups.create!(
      fingerprint: "retention_test_fp",
      error_class: "OldError",
      message: "ancient",
      status: :unresolved,
      first_seen_at: 200.days.ago,
      last_seen_at: 100.days.ago
    )
  end

  test "deletes occurrences older than 90 days" do
    old = @error_group.occurrences.create!(occurred_at: 100.days.ago, message: "old")
    recent = @error_group.occurrences.create!(occurred_at: 1.day.ago, message: "recent")

    RetentionCleanupJob.perform_now

    assert_not Occurrence.exists?(old.id), "Old occurrence should be deleted"
    assert Occurrence.exists?(recent.id), "Recent occurrence should remain"
  end

  test "does not decrement occurrences_count" do
    @error_group.occurrences.create!(occurred_at: 100.days.ago, message: "old")
    @error_group.occurrences.create!(occurred_at: 1.day.ago, message: "recent")
    @error_group.reload
    original_count = @error_group.occurrences_count

    RetentionCleanupJob.perform_now

    assert_equal original_count, @error_group.reload.occurrences_count,
      "occurrences_count should be lifetime total, not affected by retention sweep"
  end

  test "respects OOPSIE_RETENTION_DAYS env var" do
    @error_group.occurrences.create!(occurred_at: 40.days.ago, message: "40 days old")

    # Default 90 days: should NOT delete
    RetentionCleanupJob.perform_now
    assert_equal 1, @error_group.occurrences.count

    # Custom 30 days: should delete
    ENV["OOPSIE_RETENTION_DAYS"] = "30"
    RetentionCleanupJob.perform_now
    assert_equal 0, @error_group.occurrences.count
  ensure
    ENV.delete("OOPSIE_RETENTION_DAYS")
  end

  test "preserves error groups with no remaining occurrences" do
    @error_group.occurrences.create!(occurred_at: 100.days.ago, message: "old")

    RetentionCleanupJob.perform_now

    assert ErrorGroup.exists?(@error_group.id), "ErrorGroup should be kept for historical reference"
  end
end
