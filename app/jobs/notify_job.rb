class NotifyJob < ApplicationJob
  queue_as :default

  def perform(error_group_id:, occurrence_id:, is_regression: false)
    error_group = ErrorGroup.find_by(id: error_group_id)
    return unless error_group

    occurrence = Occurrence.find_by(id: occurrence_id)
    return unless occurrence

    project = error_group.project
    rules = project.notification_rules.where(enabled: true)

    rules.find_each do |rule|
      case rule.channel
      when "email"
        OopsieMailer.error_notification(
          notification_rule: rule,
          error_group: error_group,
          occurrence: occurrence,
          is_regression: is_regression
        ).deliver_later
      when "webhook"
        WebhookDeliveryJob.perform_later(
          notification_rule_id: rule.id,
          error_group_id: error_group.id,
          occurrence_id: occurrence.id,
          is_regression: is_regression
        )
      end
    end
  end
end
