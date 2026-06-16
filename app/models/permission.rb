class Permission < ApplicationRecord
  has_many :user_permissions, dependent: :destroy
  has_many :users, through: :user_permissions

  validates :name, presence: true, uniqueness: true,
                   format: { with: /\A[a-z_]+:[a-z_]+\z/, message: "must look like resource:action" }
end
