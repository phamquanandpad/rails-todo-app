class CreateUsers < ActiveRecord::Migration[7.2]
  def change
    create_table :users do |t|
      t.string :username
      t.string :email
      t.string :password
      t.datetime :deleted_at

      t.timestamps
    end
  end
end
