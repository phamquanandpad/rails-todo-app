class CreateTodos < ActiveRecord::Migration[7.2]
  def change
    create_table :todos do |t|
      t.integer :user_id
      t.string :task
      t.text :description
      t.integer :status
      t.datetime :deleted_at

      t.timestamps
    end
  end
end
