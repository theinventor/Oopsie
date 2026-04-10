class ApplicationMailer < ActionMailer::Base
  default from: ENV.fetch("OOPSIE_FROM_EMAIL", "notifications@example.com")
  layout "mailer"
end
