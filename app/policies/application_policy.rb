class ApplicationPolicy
  class Unauthorized < StandardError
    def initialize(msg = "Unauthorized")
      super
    end
  end

  class Forbidden < StandardError
    def initialize(msg = "Forbidden")
      super
    end
  end

  class UnprocessableEntity < StandardError
    def initialize(msg = "Validation failed")
      super
    end
  end

  def initialize(current_user, record)
    @current_user = current_user
    @record = record
  end

  private

  attr_reader :current_user, :record

  def permit!(permission_name)
    raise Forbidden unless current_user.can?(permission_name)

    true
  end

  def permit_owner!(permission_name, user_id)
    permit!(permission_name)

    raise Forbidden unless current_user.id == user_id

    true
  end
end
