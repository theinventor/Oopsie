class RetentionCleanupJob < ApplicationJob
  queue_as :default

  def perform
    retention_days = ENV.fetch("OOPSIE_RETENTION_DAYS", 90).to_i
    cutoff = retention_days.days.ago

    # Use raw SQL to avoid triggering counter_cache decrements.
    # occurrences_count is a lifetime total, not a count of stored rows.
    deleted = Occurrence.where("occurred_at < ?", cutoff).delete_all

    Rails.logger.info "[Oopsie] Retention cleanup: deleted #{deleted} occurrences older than #{retention_days} days"
  end
end
