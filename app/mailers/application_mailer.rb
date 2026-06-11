class ApplicationMailer < ActionMailer::Base
  default from: -> { Rails.application.credentials.mail_from || "no-reply@todo.test" }
  layout "mailer"
end
