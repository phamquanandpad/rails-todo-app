class ReplaceEmailUniqueIndexWithActiveEmailIndex < ActiveRecord::Migration[8.1]
  def up
    remove_index :users, :email, if_exists: true

    execute <<~SQL
      ALTER TABLE users
        ADD COLUMN active_email VARCHAR(255)
          GENERATED ALWAYS AS (IF(deleted_at IS NULL, email, NULL)) VIRTUAL;
    SQL

    add_index :users, :active_email, unique: true, name: "index_users_on_active_email"
  end

  def down
    remove_index :users, name: "index_users_on_active_email", if_exists: true

    execute "ALTER TABLE users DROP COLUMN active_email"

    add_index :users, :email, unique: true
  end
end
