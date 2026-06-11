class NotificationPolicy < ApplicationPolicy
  def index? = permit!("notifications:index")
  def read_all? = permit!("notifications:read_all")
  def read? = permit_owner!("notifications:read", record.user_id)
end
