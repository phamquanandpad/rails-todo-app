class CreateUserPermissions < ActiveRecord::Migration[7.2]
  def change
    create_table :user_permissions do |t|
      t.references :user, null: false, foreign_key: true
      t.references :permission, null: false, foreign_key: true

      t.timestamps
    end

    add_index :user_permissions, [:user_id, :permission_id], unique: true
  end
end
