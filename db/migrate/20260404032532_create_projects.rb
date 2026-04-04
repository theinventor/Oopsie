class CreateProjects < ActiveRecord::Migration[8.1]
  def change
    create_table :projects do |t|
      t.string :name, null: false
      t.string :api_key, null: false

      t.timestamps
    end

    add_index :projects, :api_key, unique: true
  end
end
