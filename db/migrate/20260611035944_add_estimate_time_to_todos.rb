class AddEstimateTimeToTodos < ActiveRecord::Migration[8.1]
  def change
    add_column :todos, :estimate_start_at, :date
    add_column :todos, :estimate_end_at, :date

    add_index :todos, :estimate_start_at
    add_index :todos, :estimate_end_at
  end
end
