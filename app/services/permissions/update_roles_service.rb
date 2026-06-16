module Permissions
  class UpdateRolesService < BaseService
    VALID_ROLES = AppConstants::Roles::PERMISSIONS.keys.map(&:to_s).freeze

    def initialize(permission:, roles:)
      @permission     = permission
      @requested_roles = Array(roles).map(&:to_s) & VALID_ROLES
    end

    def call
      current_roles = UserPermission.joins(:user)
        .where(permission: @permission)
        .distinct
        .pluck("users.role")
        .map(&:to_s)
        .uniq

      grant_to_roles(@requested_roles - current_roles)
      revoke_from_roles(current_roles - @requested_roles)

      success(data: { permission: @permission })
    end

    private

    def grant_to_roles(roles)
      roles.each do |role|
        user_ids    = User.active.where(role: role).pluck(:id)
        existing    = UserPermission.where(permission: @permission, user_id: user_ids).pluck(:user_id)
        missing_ids = user_ids - existing
        next if missing_ids.empty?

        UserPermission.insert_all(missing_ids.map { |uid| { user_id: uid, permission_id: @permission.id } })
      end
    end

    def revoke_from_roles(roles)
      roles.each do |role|
        user_ids = User.active.where(role: role).pluck(:id)
        UserPermission.where(permission: @permission, user_id: user_ids).delete_all
      end
    end
  end
end
