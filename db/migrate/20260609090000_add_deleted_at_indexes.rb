class AddDeletedAtIndexes < ActiveRecord::Migration[7.2]
  def change
    add_index :users, :deleted_at, if_not_exists: true
    add_index :todos, :deleted_at, if_not_exists: true
    add_index :refresh_tokens, :deleted_at, if_not_exists: true
  end
end
