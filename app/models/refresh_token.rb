class RefreshToken < ApplicationRecord
  belongs_to :user

  scope :active, -> { where(deleted_at: nil) }
  scope :valid, -> { active.where("expires_at > ?", Time.current) }

  def expired?
    expires_at <= Time.current
  end

  def revoke!
    update!(deleted_at: Time.current)
  end
end
