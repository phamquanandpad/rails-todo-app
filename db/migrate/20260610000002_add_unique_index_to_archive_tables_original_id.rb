class AddUniqueIndexToArchiveTablesOriginalId < ActiveRecord::Migration[7.2]
  def change
    remove_index :archived_todos, :original_id
    add_index :archived_todos, :original_id, unique: true

    remove_index :archived_users, :original_id
    add_index :archived_users, :original_id, unique: true
  end
end
