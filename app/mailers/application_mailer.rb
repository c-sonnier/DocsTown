class ApplicationMailer < ActionMailer::Base
  default from: "digest@docstown.org"
  layout "mailer"
end
