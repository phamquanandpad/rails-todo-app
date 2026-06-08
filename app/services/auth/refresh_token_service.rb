module Auth
  class RefreshTokenService < BaseService
    def initialize(refresh_token:)
      @refresh_token = refresh_token
    end

    def call
      return failure(errors: "Refresh token is required") if @refresh_token.blank?

      data = nil

      RefreshToken.transaction do
        record = RefreshToken.valid.lock.find_by(token: @refresh_token)
        raise ActiveRecord::RecordNotFound unless record

        user = record.user
        raise StandardError, "User not found" unless user.active?

        record.revoke!
        new_refresh = user.refresh_tokens.create!(
          token: SecureRandom.hex(AppConstants::Auth::REFRESH_TOKEN_BYTE_LENGTH),
          expires_at: AppConstants::Auth::REFRESH_TOKEN_TTL.from_now
        )

        access_token = Auth::JwtService.encode({ user_id: user.id })
        data = { accessToken: access_token, refreshToken: new_refresh.token }
      end

      success(data: data)
    rescue ActiveRecord::RecordNotFound
      failure(errors: "Invalid or expired refresh token")
    rescue => e
      failure(errors: e.message)
    end
  end
end
