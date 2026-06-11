class AddEstimateTimeToArchivedTodos < ActiveRecord::Migration[8.1]
  def change
    add_column :archived_todos, :estimate_start_at, :date
    add_column :archived_todos, :estimate_end_at, :date
  end
end
