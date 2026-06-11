class User < ApplicationRecord
  USERNAME_MIN_LENGTH = 2
  USERNAME_MAX_LENGTH = 50

  has_secure_password
  has_many :todos, dependent: :destroy, foreign_key: :user_id
  has_many :refresh_tokens, dependent: :destroy
  has_many :notifications, dependent: :destroy
  has_many :user_permissions, dependent: :destroy
  has_many :permissions, through: :user_permissions

  enum :role, { member: 0, admin: 1 }, default: :member

  before_validation :normalize_email

  scope :active, -> { where(deleted_at: nil) }

  validates :username, presence: true, length: { minimum: USERNAME_MIN_LENGTH, maximum: USERNAME_MAX_LENGTH }
  validates :email, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }

  def can?(permission_name)
    permissions.exists?(name: permission_name)
  end

  def soft_delete!
    update!(deleted_at: Time.current)
    SoftDeleteUserTodosJob.perform_later(id)
  end

  def active?
    deleted_at.nil?
  end

  private

  def normalize_email
    self.email = email&.downcase&.strip
  end
end
