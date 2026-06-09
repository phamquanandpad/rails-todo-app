class Api::V1::AuthController < ApplicationController
  skip_before_action :authenticate_request!, only: [ :register, :login, :refresh ]

  def register
    result = Auth::RegisterService.call(
      username: params[:username],
      email: params[:email],
      password: params[:password],
      password_confirmation: params[:password_confirmation]
    )

    raise ApplicationPolicy::UnprocessableEntity, result.errors unless result.success?

    @user = result.data[:user]
    render :register, status: :created
  end

  def login
    result = Auth::LoginService.call(
      email: params[:email],
      password: params[:password]
    )

    raise ApplicationPolicy::Unauthorized, result.errors unless result.success?

    @user          = result.data[:user]
    @access_token  = result.data[:accessToken]
    @refresh_token = result.data[:refreshToken]
  end

  def refresh
    result = Auth::RefreshTokenService.call(
      refresh_token: params[:refresh_token]
    )

    raise ApplicationPolicy::Unauthorized, result.errors unless result.success?

    @access_token  = result.data[:accessToken]
    @refresh_token = result.data[:refreshToken]
  end

  def logout
    token = RefreshToken.valid.find_by(token: params[:refresh_token], user_id: current_user.id)
    token&.revoke!
    head :no_content
  end
end
