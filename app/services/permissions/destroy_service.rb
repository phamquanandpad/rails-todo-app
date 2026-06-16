module Permissions
  class DestroyService < BaseService
    def initialize(permission:)
      @permission = permission
    end

    def call
      if AppConstants::Roles::ALL.include?(@permission.name)
        return failure(errors: ["#{@permission.name} is a built-in permission and cannot be deleted via the API"])
      end

      @permission.destroy!
      success(data: { permission: @permission })
    rescue ActiveRecord::RecordNotDestroyed => e
      failure(errors: e.record.errors.full_messages)
    end
  end
end
