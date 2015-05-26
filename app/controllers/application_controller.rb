class ApplicationController < ActionController::Base
  rescue_from DeviseLdapAuthenticatable::LdapException do |exception|
    render :text => exception, :status => 500
  end
  before_filter do
    resource = controller_path.singularize.gsub('/', '_').to_sym
    method = "#{resource}_params"
    params[resource] &&= send(method) if respond_to?(method, true)
  end
  helper Openseadragon::OpenseadragonHelper
  # Adds a few additional behaviors into the application controller
  include Blacklight::Controller
# Adds Sufia behaviors into the application controller
  include Sufia::Controller

  include Hydra::Controller::ControllerBehavior
  layout 'sufia-one-column'

  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  # Add username - from https://github.com/plataformatec/devise/wiki/How-To%3a-Allow-users-to-sign-in-using-their-username-or-email-address
  before_action :configure_permitted_parameters, if: :devise_controller?

  protected

  def configure_permitted_parameters
    devise_parameter_sanitizer.for(:sign_up) { |u| u.permit(:username, :email, :password, :password_confirmation, :remember_me) }
    devise_parameter_sanitizer.for(:sign_in) { |u| u.permit(:login, :username, :email, :password, :remember_me) }
    devise_parameter_sanitizer.for(:account_update) { |u| u.permit(:username, :email, :password, :password_confirmation, :current_password) }
  end
end
