module AppConstants
  module Auth
    JWT_ALGORITHM             = "HS256"
    ACCESS_TOKEN_TTL          = 1.hour
    REFRESH_TOKEN_TTL         = 7.days
    REFRESH_TOKEN_BYTE_LENGTH = 32
  end

  module Roles
    PERMISSIONS = {
      admin: %w[
        users:show
        users:update
        users:destroy

        todos:index
        todos:show
        todos:create
        todos:update
        todos:destroy
        todos:complete
      ].freeze,
      member: %w[
        todos:index
        todos:show
        todos:create
        todos:update
        todos:destroy
        todos:complete
      ].freeze
    }.freeze

    ALL = PERMISSIONS.values.flatten.uniq.freeze
  end
end
