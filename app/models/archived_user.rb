class ArchivedUser < ApplicationRecord
  enum :role, { member: 0, admin: 1 }
end
