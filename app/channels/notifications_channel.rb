class NotificationsChannel < ApplicationCable::Channel
  def subscribed
    stream_for current_user
    transmit({ connected: true, unread: current_user.notifications.unread.count })
  end
end
