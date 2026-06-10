module Permissions
  # Idempotent sync of the permission catalogue and per-user grants against the
  # role map in AppConstants::Roles. Run after introducing a new permission so
  # that existing users (who only get permissions at signup) receive it too.
  #
  #   1. Creates any Permission rows named in Roles::ALL that don't exist yet.
  #   2. For each user, grants any permissions their role should have but that
  #      they're currently missing.
  #
  # Safe to run repeatedly — it never duplicates or removes anything.
  class SyncService < BaseService
    BATCH_SIZE = 500

    def call
      created_permissions = ensure_permissions_exist
      granted = backfill_user_permissions

      success(data: { permissions_created: created_permissions, permissions_granted: granted })
    end

    private

    def ensure_permissions_exist
      existing = Permission.where(name: AppConstants::Roles::ALL).pluck(:name)
      missing  = AppConstants::Roles::ALL - existing
      return 0 if missing.empty?

      Permission.insert_all(missing.map { |name| { name: name } })
      missing.size
    end

    def backfill_user_permissions
      permission_id_by_name = Permission.pluck(:name, :id).to_h
      granted = 0

      User.includes(:user_permissions).find_each(batch_size: BATCH_SIZE) do |user|
        desired_names = AppConstants::Roles::PERMISSIONS[user.role.to_sym] || []
        next if desired_names.empty?

        desired_ids = desired_names.filter_map { |name| permission_id_by_name[name] }
        owned_ids   = user.user_permissions.map(&:permission_id)
        missing_ids = desired_ids - owned_ids
        next if missing_ids.empty?

        UserPermission.insert_all(missing_ids.map { |pid| { user_id: user.id, permission_id: pid } })
        granted += missing_ids.size
      end

      granted
    end
  end
end
