class AddUsersIndexPermission < ActiveRecord::Migration[7.2]
  def up
    permission = Permission.find_or_create_by!(name: "users:index")

    admin_ids = User.active.where(role: :admin).pluck(:id)
    return if admin_ids.empty?

    existing_ids = UserPermission
      .where(permission: permission, user_id: admin_ids)
      .pluck(:user_id)
    missing_ids = admin_ids - existing_ids

    now = Time.current
    UserPermission.insert_all(
      missing_ids.map { |uid| { user_id: uid, permission_id: permission.id, created_at: now, updated_at: now } }
    ) if missing_ids.any?
  end

  def down
    permission = Permission.find_by(name: "users:index")
    return unless permission

    admin_ids = User.active.where(role: :admin).pluck(:id)
    UserPermission.where(permission: permission, user_id: admin_ids).delete_all
    permission.destroy! unless UserPermission.where(permission: permission).exists?
  end
end
