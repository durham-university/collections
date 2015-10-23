class User < ActiveRecord::Base
  # Connects this user object to Hydra behaviors.
  include Hydra::User
  # Connects this user object to Role-management behaviors.
  include Hydra::RoleManagement::UserRoles
  # Connects this user object to Sufia behaviors.
  include Sufia::User
  include Sufia::UserUsageStats



  if Blacklight::Utils.needs_attr_accessible?

    attr_accessible :email, :password, :password_confirmation
  end
  # Connects this user object to Blacklights Bookmarks.
  include Blacklight::User
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :ldap_authenticatable, :rememberable, :trackable

  # Method added by Blacklight; Blacklight uses #to_s on your
  # user class to get a user-displayable login/identifier for
  # the account.
  def to_s
    username
  end

  def ldap_before_save
    self.email = Devise::LDAP::Adapter.get_ldap_param(self.username,"mail").first
    self.display_name = Devise::LDAP::Adapter.get_ldap_param(self.username,"initials").first + " " + Devise::LDAP::Adapter.get_ldap_param(self.username,"sn").first
    self.department = Devise::LDAP::Adapter.get_ldap_param(self.username,"department").first
  end

  # Override audituser and batchuser methods from Sufia to handle correctly our
  # user model.
  def self.audituser
    User.find_by_user_key(audituser_key) || User.create!(Devise.authentication_keys.first => audituser_key, password: Devise.friendly_token[0,20], email: audituser_email )
  end

  def self.batchuser
    User.find_by_user_key(batchuser_key) || User.create!(Devise.authentication_keys.first => batchuser_key, password: Devise.friendly_token[0,20], email: batchuser_email )
  end

  def self.audituser_key
    'audituser'
  end

  def self.batchuser_key
    'batchuser'
  end

  # These emails aren't used for anything but they need to be something unique
  # because of database unique constraint on email
  def self.audituser_email
    'audituser@example.com'
  end

  def self.batchuser_email
    'batch@example.com'
  end

  attr_accessor :login
end
