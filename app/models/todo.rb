class Todo < ApplicationRecord
  TASK_MAX_LENGTH = 255

  belongs_to :user, foreign_key: :user_id

  scope :active,      -> { where(deleted_at: nil) }
  scope :deleted,     -> { where.not(deleted_at: nil) }
  scope :starting_on, ->(date) { where(estimate_start_at: date) }
  scope :overdue_by,  ->(date) { where(estimate_end_at: ..date) }

  enum :status, { pending: 0, in_progress: 1, completed: 2 }

  validates :task, presence: true, length: { maximum: TASK_MAX_LENGTH }
  validates :user, presence: true
  validate :estimate_window_consistent

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

  def overdue?(today = Date.current)
    estimate_end_at.present? && estimate_end_at <= today && !completed?
  end

  private

  def estimate_window_consistent
    return if estimate_start_at.blank? || estimate_end_at.blank?
    return if estimate_end_at >= estimate_start_at

    errors.add(:estimate_end_at, "must be on or after estimateStartAt")
  end
end
