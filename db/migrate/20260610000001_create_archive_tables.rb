class CreateArchiveTables < ActiveRecord::Migration[7.2]
  def change
    create_table :archived_todos do |t|
      t.bigint   :original_id, null: false
      t.bigint   :user_id,     null: false
      t.string   :task,        null: false
      t.text     :description
      t.integer  :status,      null: false, default: 0
      t.datetime :deleted_at
      t.datetime :original_created_at
      t.datetime :original_updated_at
      t.datetime :archived_at, null: false
      t.timestamps
    end
    add_index :archived_todos, :original_id
    add_index :archived_todos, :user_id
    add_index :archived_todos, :archived_at

    create_table :archived_users do |t|
      t.bigint   :original_id, null: false
      t.string   :username,    null: false
      t.string   :email,       null: false
      t.string   :password_digest
      t.integer  :role,        null: false, default: 0
      t.datetime :deleted_at
      t.datetime :original_created_at
      t.datetime :original_updated_at
      t.datetime :archived_at, null: false
      t.timestamps
    end
    add_index :archived_users, :original_id
    add_index :archived_users, :archived_at
  end
end
