class AddEmailSentAtToNotifications < ActiveRecord::Migration[8.1]
  def change
    add_column :notifications, :email_sent_at, :datetime
    add_index  :notifications, :email_sent_at
  end
end
