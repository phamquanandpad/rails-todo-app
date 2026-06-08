class FixTodosConstraintsAndForeignKey < ActiveRecord::Migration[7.2]
  def change
    change_column :todos, :user_id, :bigint
    change_column_null :todos, :user_id, false
    change_column_null :todos, :task, false
    change_column :todos, :status, :integer, null: false, default: 0

    add_index :todos, :user_id unless index_exists?(:todos, :user_id)
    add_foreign_key :todos, :users
  end
end
