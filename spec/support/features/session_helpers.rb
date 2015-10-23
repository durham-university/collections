# spec/support/features/session_helpers.rb
module Features
  module SessionHelpers
    def sign_in(who = :user)
      logout
      user = who.is_a?(User) ? who : FactoryGirl.build(:user).tap(&:save!)
      Warden.test_mode!
      login_as(user, scope: :user)
    end
  end
end
