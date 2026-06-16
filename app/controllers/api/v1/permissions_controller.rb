class Api::V1::PermissionsController < ApplicationController
  before_action :authorize_permission_collection!, only: [:index, :create]
  before_action :set_permission, only: [:show, :update, :destroy, :users, :grant_user, :revoke_user]
  before_action -> { authorize!(@permission) }, only: [:show, :update, :destroy, :users, :grant_user, :revoke_user]
  before_action :set_permission_user, only: [:grant_user, :revoke_user]

  def index
    permissions = PermissionsQuery.new(Permission.all).call(filter_params)
    @pagy, @permissions = pagy(permissions, limit: params[:limit])
    @permission_roles = permission_roles_map(@permissions)
  end

  def show
    @permission_roles = permission_roles_map([@permission])
  end

  def create
    @permission = Permission.new(create_params)
    @permission.save!
    @permission_roles = {}
    render :show, status: :created
  end

  def update
    @permission.update!(update_params)
    if params.key?(:roles)
      result = Permissions::UpdateRolesService.call(permission: @permission, roles: params[:roles])
      raise ApplicationPolicy::UnprocessableEntity, result.errors.join(", ") if result.failure?
    end
    @permission_roles = permission_roles_map([@permission])
    render :show
  end

  def destroy
    result = Permissions::DestroyService.call(permission: @permission)
    raise ApplicationPolicy::UnprocessableEntity, result.errors.join(", ") if result.failure?

    head :no_content
  end

  def users
    head :no_content  # temporary stub
  end

  def grant_user
    head :no_content  # temporary stub
  end

  def revoke_user
    head :no_content  # temporary stub
  end

  private

  def set_permission
    @permission = Permission.find(params[:id])
  end

  def set_permission_user
    @permission_user = User.active.find(params[:user_id])
  end

  def authorize_permission_collection!
    authorize!(Permission.new)
  end

  def create_params
    params.permit(:name, :description)
  end

  def update_params
    params.permit(:description)
  end

  def filter_params
    params.permit(:q)
  end

  def permission_roles_map(permissions)
    ids = permissions.map(&:id)
    return {} if ids.empty?

    UserPermission.joins(:user)
      .where(permission_id: ids)
      .distinct
      .pluck(:permission_id, "users.role")
      .each_with_object(Hash.new { |h, k| h[k] = [] }) { |(pid, role), h| h[pid] << role }
  end
end
