class NotificationMailer < ApplicationMailer
  after_deliver :stamp_sent_at

  # @param notification [Notification]
  def notify(notification)
    @notification = notification
    @user         = notification.user
    @link_url     = absolute_link(notification.link)

    mail(
      to:      @user.email,
      subject: @notification.title
    )
  end

  private

  def absolute_link(link)
    return nil if link.blank?

    base   = Rails.application.config.action_mailer.default_url_options || {}
    host   = base[:host]
    port   = base[:port]
    scheme = Rails.env.production? ? "https" : "http"
    URI::Generic.build(scheme: scheme, host: host, port: port, path: link).to_s
  end

  def stamp_sent_at
    @notification&.update_column(:email_sent_at, Time.current)
  end
end
