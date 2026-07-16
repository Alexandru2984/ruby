class ApplicationMailer < ActionMailer::Base
  default from: ENV.fetch("MAILER_FROM", "bookmarks@ruby.micutu.com")
  layout "mailer"
end
