AppConstants::Roles::ALL.each { |name| Permission.find_or_create_by!(name: name) }

def seed_user(email:, username:, password:, role:)
  user = User.find_or_initialize_by(email: email)
  return unless user.new_record?

  user.assign_attributes(username: username, password: password, password_confirmation: password, role: role)
  user.save!

  permission_ids = Permission.where(name: AppConstants::Roles::PERMISSIONS[role]).pluck(:id)
  UserPermission.insert_all(permission_ids.map { |pid| { user_id: user.id, permission_id: pid } })
end

seed_user(email: "admin@example.com",  username: "admin",  password: "Admin123!",  role: :admin)
seed_user(email: "member@example.com", username: "member", password: "Member123!", role: :member)
