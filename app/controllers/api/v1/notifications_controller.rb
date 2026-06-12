class Api::V1::NotificationsController < ApplicationController
  before_action :set_notification, only: [ :read ]
  before_action -> { authorize!(@notification) }, only: [ :read ]
  before_action -> { authorize!(Notification.new) }, only: [ :index, :read_all, :demo ]

  # GET /api/v1/notifications
  def index
    @pagy, @notifications = pagy(scope.recent, limit: params[:limit])
  end

  # PATCH /api/v1/notifications/:id/read
  def read
    notification = scope.find(params[:id])
    notification.mark_read!
    head :no_content
  end

  # POST /api/v1/notifications/read_all
  def read_all
    scope.unread.update_all(read_at: Time.current)
    head :no_content
  end

  # POST /api/v1/notifications/demo
  def demo
    result = Notifications::CreateService.call(
      user:  current_user,
      title: "🔔 Test notification",
      body:  "Real-time is working! Sent at #{Time.current.strftime('%H:%M:%S')}",
      link:  "/",
      send_email: false
    )
    if result.success?
      render json: result.data[:notification].as_cable_json, status: :created
    else
      render json: { errors: result.errors }, status: :unprocessable_entity
    end
  end

  private

  def scope
    current_user.notifications
  end

  def set_notification
    @notification = scope.find(params[:id])
  end
end
