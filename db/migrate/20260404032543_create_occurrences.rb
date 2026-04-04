class CreateOccurrences < ActiveRecord::Migration[8.1]
  def change
    create_table :occurrences do |t|
      t.references :error_group, null: false, foreign_key: true
      t.string :message
      t.json :backtrace
      t.json :first_line
      t.json :causes
      t.boolean :handled, null: false, default: false
      t.json :context
      t.string :environment
      t.json :server_info
      t.datetime :occurred_at, null: false
      t.string :notifier_version

      t.timestamps
    end

    add_index :occurrences, [ :error_group_id, :occurred_at ]
  end
end
