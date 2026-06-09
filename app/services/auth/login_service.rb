  class Auth::LoginService < BaseService
    def initialize(email:, password:)
      @email = email.downcase.strip
      @password = password
    end

    def call
      user = User.active.find_by(email: @email)

      unless user&.authenticate(@password)
        return failure(errors: "Invalid email or password")
      end

      tokens = generate_tokens(user)
      success(data: { user: serialize_user(user), **tokens })
    end

    private

    def generate_tokens(user)
      access_token = Auth::JwtService.encode({ user_id: user.id })
      refresh_token = user.refresh_tokens.create!(
        token: SecureRandom.hex(AppConstants::Auth::REFRESH_TOKEN_BYTE_LENGTH),
        expires_at: AppConstants::Auth::REFRESH_TOKEN_TTL.from_now
      )
      { accessToken: access_token, refreshToken: refresh_token.token }
    end

    def serialize_user(user)
      { username: user.username, email: user.email }
    end
  end
