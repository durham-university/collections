require 'ntlm/smtp'

ActionMailer::Base.smtp_settings = {
   address: "smtp.dur.ac.uk",
   port: "587",
   user_name: Rails.application.secrets.smtp_user,
   password: Rails.application.secrets.smtp_password,
   authentication: "ntlm",
}
