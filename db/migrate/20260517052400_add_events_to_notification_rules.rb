class AddEventsToNotificationRules < ActiveRecord::Migration[8.1]
  def change
    add_column :notification_rules, :events, :json unless column_exists?(:notification_rules, :events)
  end
end
