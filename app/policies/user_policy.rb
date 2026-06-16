class UserPolicy < ApplicationPolicy
  # Users::ChangeRoleService is an admin-only operation.
  # We gate on users:index (admin-exclusive) because users:update is also granted to members.
  def index?       = permit!("users:index")
  def show?        = permit_owner!("users:show", record.id)
  def update?      = permit_owner!("users:update", record.id)
  def update_role? = permit!("users:index")
  def destroy?     = permit_owner!("users:destroy", record.id)
end
