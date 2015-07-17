require 'mail_form'

class ContactForm < MailForm::Base
  ISSUE_TYPES = [
      ["Depositing content", "Depositing content"],
      ["Obtaining a DOI", "Obtaining a DOI"],
      ["Making changes to my content", "Making changes to my content"],
      ["Browsing and searching", "Browsing and searching"],
      ["Reporting a problem", "Reporting a problem"],
      ["General enquiry or request", "General enquiry or request"]
    ]
  attribute :contact_method, captcha: true
  attribute :category, validate: true
  attribute :name, validate: true
  attribute :email, validate: /\A([\w\.%\+\-']+)@([\w\-]+\.)+([\w]{2,})\z/i
  attribute :subject, validate: true
  attribute :message, validate: true

  attr_accessor :message_from
  # - can't use this without ActiveRecord::Base validates_inclusion_of :issue_type, in: ISSUE_TYPES

  # Declare the e-mail headers. It accepts anything the mail method
  # in ActionMailer accepts.
  def headers
    {
      subject: "[Collections] #{subject}",
      to: Sufia.config.contact_email,
      from: message_from
    }
  end
end
