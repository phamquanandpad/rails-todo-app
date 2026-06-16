module Users
  class ChangeRoleService < BaseService
    VALID_ROLES = AppConstants::Roles::PERMISSIONS.keys.map(&:to_s).freeze

    def initialize(user:, role:)
      @user = user
      @role = role.to_s
    end

    def call
      return failure(errors: ["Invalid role: #{@role}"]) unless VALID_ROLES.include?(@role)
      return success(data: { user: @user }) if @user.role.to_s == @role

      ActiveRecord::Base.transaction do
        @user.user_permissions.delete_all
        @user.update!(role: @role)
        backfill_permissions
      end

      success(data: { user: @user })
    rescue ActiveRecord::RecordInvalid => e
      failure(errors: e.record.errors.full_messages)
    end

    private

    def backfill_permissions
      desired_names = AppConstants::Roles::PERMISSIONS[@role.to_sym] || []
      return if desired_names.empty?

      permission_ids = Permission.where(name: desired_names).pluck(:id)
      return if permission_ids.empty?

      now = Time.current
      UserPermission.insert_all(
        permission_ids.map { |pid| { user_id: @user.id, permission_id: pid, created_at: now, updated_at: now } }
      )
    end
  end
end
