class Todo < ApplicationRecord
  TASK_MAX_LENGTH = 255

  belongs_to :user, foreign_key: :user_id

  scope :active,   -> { where(deleted_at: nil) }
  scope :deleted,  -> { where.not(deleted_at: nil) }

  enum :status, { pending: 0, in_progress: 1, completed: 2 }

  validates :task, presence: true, length: { maximum: TASK_MAX_LENGTH }
  validates :user, presence: true

  def soft_delete!
    update!(deleted_at: Time.current)
  end

  def restore!
    update!(deleted_at: nil)
  end

  def active?
    deleted_at.nil?
  end

  def deleted?
    deleted_at.present?
  end
end
