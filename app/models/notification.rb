class Notification < ApplicationRecord
  belongs_to :user

  validates :title, presence: true

  scope :unread, -> { where(read_at: nil) }
  scope :recent, -> { order(created_at: :desc) }

  def read? = read_at.present?

  def mark_read!
    update!(read_at: Time.current) unless read?
  end

  def as_cable_json
    {
      id:        id,
      title:     title,
      body:      body,
      link:      link,
      read:      read?,
      createdAt: created_at.iso8601
    }
  end
end
