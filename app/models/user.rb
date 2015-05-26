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

  attr_accessor :login
end
