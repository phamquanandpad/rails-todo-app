class TodoPolicy < ApplicationPolicy
  def index?   = permit!("todos:index")
  def show?    = permit_owner!("todos:show", record.user_id)
  def create?  = permit!("todos:create")
  def update?  = permit_owner!("todos:update", record.user_id)
  def destroy? = permit_owner!("todos:destroy", record.user_id)
  def complete? = permit_owner!("todos:complete", record.user_id)
end
