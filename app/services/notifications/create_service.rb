module Notifications
  class CreateService < BaseService
    def initialize(user:, title:, body: nil, link: nil, send_email: true)
      @user       = user
      @title      = title
      @body       = body
      @link       = link
      @send_email = send_email
    end

    def call
      notification = @user.notifications.create!(title: @title, body: @body, link: @link)
      broadcast(notification)
      enqueue_email(notification) if @send_email
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

    def enqueue_email(notification)
      return if notification.user.email.blank?

      NotificationMailer.notify(notification).deliver_later(queue: :mailers)
    rescue StandardError => e
      # Enqueue must never break the caller; the row is already saved.
      Rails.logger.warn("[notifications] enqueue email failed: #{e.message}")
    end
  end
end
