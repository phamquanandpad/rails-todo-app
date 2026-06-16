class Api::V1::UsersController < ApplicationController
  before_action :set_user, only: [:show, :update, :destroy]
  before_action :set_any_user, only: [:update_role]
  before_action -> { authorize!(@user) }, only: [:show, :update, :destroy, :update_role]
  before_action :authorize_user_collection!, only: [:index]

  def index
    scope = User.active.includes(:user_permissions).order(:username)
    if params[:q].present?
      q = ActiveRecord::Base.sanitize_sql_like(params[:q])
      scope = scope.where("username LIKE ? OR email LIKE ?", "#{q}%", "#{q}%")
    end
    limit = params[:limit].to_i
    limit = 20 if limit <= 0
    limit = [limit, 100].min
    @pagy, @users = pagy(scope, limit: limit)
  end

  def show; end

  def update
    @user.update!(user_params)
  end

  def update_role
    result = ::Users::ChangeRoleService.call(user: @user, role: params[:role])
    raise ApplicationPolicy::UnprocessableEntity, result.errors.join(", ") if result.failure?

    render :show
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

  def set_any_user
    @user = User.active.find(params[:id])
  end

  def authorize_user_collection!
    authorize!(User.new)
  end

  def user_params
    params.permit(:username, :email, :password, :password_confirmation)
  end
end
