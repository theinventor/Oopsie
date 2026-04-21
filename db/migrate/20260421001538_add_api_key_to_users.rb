class AddApiKeyToUsers < ActiveRecord::Migration[8.1]
  def up
    add_column :users, :api_key, :string

    # Backfill existing users with unique keys
    execute <<~SQL
      UPDATE users SET api_key = hex(randomblob(32)) WHERE api_key IS NULL
    SQL

    change_column_null :users, :api_key, false
    add_index :users, :api_key, unique: true
  end

  def down
    remove_index :users, :api_key
    remove_column :users, :api_key
  end
end
