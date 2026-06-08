class UserPolicy < ApplicationPolicy
  def show?    = permit_owner!("users:show", record.id)
  def update?  = permit_owner!("users:update", record.id)
  def destroy? = permit_owner!("users:destroy", record.id)
end
