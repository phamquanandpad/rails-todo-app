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

    @user         = result.data[:user]
    @access_token = result.data[:accessToken]

    set_refresh_cookie(result.data[:refreshToken])
  end

  def refresh
    result = Auth::RefreshTokenService.call(
      refresh_token: params[:refresh_token].presence || cookies.signed[:refresh_token]
    )

    raise ApplicationPolicy::Unauthorized, result.errors unless result.success?

    @access_token = result.data[:accessToken]

    set_refresh_cookie(result.data[:refreshToken])
  end

  def logout
    token_value = params[:refresh_token].presence || cookies.signed[:refresh_token]
    token = RefreshToken.valid.find_by(token: token_value, user_id: current_user.id)
    token&.revoke!
    cookies.delete(:refresh_token, domain: :all)
    head :no_content
  end

  def me
    @user        = current_user
    @permissions = current_user.permissions.pluck(:name)
  end

  private

  def set_refresh_cookie(token)
    cookies.signed[:refresh_token] = {
      value:     token,
      httponly:  true,
      secure:    Rails.env.production?,
      same_site: :strict,
      expires:   30.days.from_now
    }
  end
end
