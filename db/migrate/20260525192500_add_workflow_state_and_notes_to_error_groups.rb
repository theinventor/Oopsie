class AddWorkflowStateAndNotesToErrorGroups < ActiveRecord::Migration[8.1]
  def change
    add_column :error_groups, :workflow_state, :integer, null: false, default: 0
    add_column :error_groups, :workflow_state_changed_at, :datetime
    add_index :error_groups, [ :project_id, :workflow_state, :last_seen_at ],
      name: "index_error_groups_on_project_workflow_last_seen"

    reversible do |dir|
      dir.up do
        execute <<~SQL.squish
          UPDATE error_groups
          SET workflow_state_changed_at = COALESCE(updated_at, created_at)
          WHERE workflow_state_changed_at IS NULL
        SQL
      end
    end

    change_column_null :error_groups, :workflow_state_changed_at, false

    create_table :error_group_notes do |t|
      t.references :error_group, null: false, foreign_key: true
      t.integer :kind, null: false, default: 0
      t.text :body
      t.string :from_value
      t.string :to_value
      t.string :actor_kind, null: false, default: "system"
      t.string :actor_label, null: false, default: "system"
      t.string :source, null: false, default: "unknown"
      t.timestamps

      t.index [ :error_group_id, :created_at ]
      t.index [ :error_group_id, :kind, :created_at ]
    end
  end
end
