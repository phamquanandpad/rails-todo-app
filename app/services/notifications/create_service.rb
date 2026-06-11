module Notifications
  class CreateService < BaseService
    def initialize(user:, title:, body: nil, link: nil)
      @user  = user
      @title = title
      @body  = body
      @link  = link
    end

    def call
      notification = @user.notifications.create!(title: @title, body: @body, link: @link)
      broadcast(notification)
      success(data: { notification: notification })
    rescue ActiveRecord::RecordInvalid => e
      failure(errors: e.record.errors.full_messages)
    end

    private

    def broadcast(notification)
      NotificationsChannel.broadcast_to(notification.user, notification.as_cable_json)
    rescue StandardError => e
      # Live push is best-effort: the row is already persisted.
      Rails.logger.warn("[notifications] broadcast failed: #{e.message}")
    end
  end
end
