module Auth
  class JwtService
    def self.encode(payload, exp: AppConstants::Auth::ACCESS_TOKEN_TTL)
      payload = payload.merge(exp: exp.from_now.to_i)
      JWT.encode(payload, secret, AppConstants::Auth::JWT_ALGORITHM)
    end

    def self.decode(token)
      return nil if token.blank?
      decoded = JWT.decode(token, secret, true, algorithm: AppConstants::Auth::JWT_ALGORITHM)
      HashWithIndifferentAccess.new(decoded.first)
    rescue JWT::DecodeError
      nil
    end

    def self.secret
      Rails.application.secret_key_base
    end
    private_class_method :secret
  end
end
