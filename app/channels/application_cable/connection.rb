module ApplicationCable
  class Connection < ActionCable::Connection::Base
    identified_by :current_user

    def connect
      self.current_user = find_verified_user
    end

    private

    def find_verified_user
      token   = request.params[:token].presence
      payload = token && Auth::JwtService.decode(token)
      user    = payload && User.active.find_by(id: payload[:user_id])
      user || reject_unauthorized_connection
    end
  end
end
