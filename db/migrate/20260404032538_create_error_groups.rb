class CreateErrorGroups < ActiveRecord::Migration[8.1]
  def change
    create_table :error_groups do |t|
      t.references :project, null: false, foreign_key: true
      t.string :fingerprint, null: false
      t.string :error_class, null: false
      t.string :message
      t.integer :status, null: false, default: 0
      t.integer :occurrences_count, null: false, default: 0
      t.datetime :first_seen_at, null: false
      t.datetime :last_seen_at, null: false

      t.timestamps
    end

    add_index :error_groups, [ :project_id, :fingerprint ], unique: true
    add_index :error_groups, [ :project_id, :status, :last_seen_at ]
  end
end
