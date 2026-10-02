class ApplicationMailer < ActionMailer::Base
  default from: Rails.env.production? ? ENV.fetch("SMTP_USERNAME") : "no-reply@book-pilot.co.uk"

  layout "mailer"
end
