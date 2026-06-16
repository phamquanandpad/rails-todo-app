class PermissionPolicy < ApplicationPolicy
  def index?        = permit!("permissions:index")
  def show?         = permit!("permissions:show")
  def create?       = permit!("permissions:create")
  def update?       = permit!("permissions:update")
  def destroy?      = permit!("permissions:destroy")
  def users?        = permit!("permissions:update")
  def grant_user?   = permit!("permissions:update")
  def revoke_user?  = permit!("permissions:update")
end
