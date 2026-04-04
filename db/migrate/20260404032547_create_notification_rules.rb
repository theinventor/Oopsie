class CreateNotificationRules < ActiveRecord::Migration[8.1]
  def change
    create_table :notification_rules do |t|
      t.references :project, null: false, foreign_key: true
      t.integer :channel, null: false
      t.string :destination, null: false
      t.boolean :enabled, null: false, default: true

      t.timestamps
    end
  end
end
