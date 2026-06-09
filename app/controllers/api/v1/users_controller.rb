class Api::V1::UsersController < ApplicationController
  before_action :set_user
  before_action -> { authorize!(@user) }, only: [:show, :update, :destroy]

  def show; end

  def update
    @user.update!(user_params)
  end

  def destroy
    @user.soft_delete!
    head :no_content
  end

  private

  def set_user
    raise ApplicationPolicy::NotFound unless params[:id].to_i == current_user.id

    @user = current_user
  end

  def user_params
    params.permit(:username, :email, :password, :password_confirmation)
  end
end
