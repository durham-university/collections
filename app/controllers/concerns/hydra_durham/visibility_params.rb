module HydraDurham
  module VisibilityParams
    extend ActiveSupport::Concern

    # Handles open-pending visibility case which is translated to authenticate
    # before persisting object. request_for_visibility_change is also set for
    # open-pending, and unset for any other visibility.
    def handle_pending_visibility_params(params,resource,metadata_key)
      # NOTE: params usually has not been sanitised, be careful!
      if params[:visibility]=='open-pending'
        params[:visibility]=Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_AUTHENTICATED
        params[metadata_key]||=ActionController::Parameters.new()
        params[metadata_key][:request_for_visibility_change]=Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC
      elsif params[:visibility]
        params[metadata_key]||=ActionController::Parameters.new()
        params[metadata_key][:request_for_visibility_change]=nil
      end
    end

    def needs_open_pending_notifications(resource)
      resource.request_for_visibility_change=='open' && \
        (resource.changed_attributes.key? :request_for_visibility_change) && \
        resource.changed_attributes['request_for_visibility_change'] != 'open'
    end

    def send_open_pending_notifications(resource,from=nil)
      recipients=DURHAM_CONFIG['visibility_notification_users']

      from||=resource.depositor
      from=User.find_by_user_key(from) if !from.is_a? User
      from_key=from.user_key
      from_name=from.display_name

      resource_path=Rails.application.routes.url_helpers.method("edit_#{resource.class.name.underscore}_path").call(resource)
      title=( (resource.title.is_a? Array) ? (resource.title.first) : (resource.title) ).to_s
      resource_link=ActionController::Base.helpers.link_to title, resource_path

      recipients.each do |recipient|
        next if recipient==from_key

        to=User.find_by_user_key recipient
        next if not to
        from.send_message(to,"#{from_name} requests that #{resource_link} be made Open Access", 'Open Access request', sanitize_text = false )
      end
      return true
    end

  end
end
