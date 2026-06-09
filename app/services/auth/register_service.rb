module Auth
  class RegisterService < BaseService
    def initialize(username:, email:, password:, password_confirmation:)
      @username = username&.strip
      @email = email&.downcase&.strip
      @password = password
      @password_confirmation = password_confirmation
    end

    def call
      user = User.new(
        username: @username,
        email: @email,
        password: @password,
        password_confirmation: @password_confirmation,
      )

      unless user.valid?
        return failure(errors: user.errors.full_messages)
      end

      User.transaction do
        user.save!
        assign_default_permissions(user)
      end
      success(data: { user: serialize_user(user) })
    rescue ActiveRecord::RecordInvalid => e
      failure(errors: e.record.errors.full_messages)
    end

    private

    def assign_default_permissions(user)
      names = AppConstants::Roles::PERMISSIONS[user.role.to_sym] || []
      return if names.empty?

      permission_ids = Permission.where(name: names).pluck(:id)
      return if permission_ids.empty?

      records = permission_ids.map { |pid| { user_id: user.id, permission_id: pid } }
      UserPermission.insert_all(records)
    end

    def serialize_user(user)
      { username: user.username, email: user.email }
    end
  end
end
