module HydraDurham
  module AccessControlsController
    extend ActiveSupport::Concern
    include HydraDurham::VisibilityParams

    included do
      before_action :pending_visibility_handler, only: [:update]
      before_action :check_can_destroy, only: [:destroy]
      around_action :visibility_request_notifications, only: [:update]
    end

    private

      def visibility_request_notifications
        resource=@resource || instance_variable_get("@#{controller_name.singularize}")
        user=@current_user || nil

        old_value=resource.request_for_visibility_change

        yield

        new_value=resource.request_for_visibility_change

        # response.status 302 indicates a redirect which means the save was successful
        if new_value=='open' && old_value!=new_value && response.status==302
          send_open_pending_notifications resource, user
        end
      end

      def check_can_destroy
        resource=@resource || instance_variable_get("@#{controller_name.singularize}")
        user=@current_user || nil
        raise "Deleting resource forbidden" if not resource.can_destroy? user
      end

      def pending_visibility_handler
        resource=@resource || instance_variable_get("@#{controller_name.singularize}")
        user=@current_user || nil

        if params[:visibility]
          metadata_key=controller_name.singularize.to_sym

          if not resource.can_change_visibility? params[:visibility], user
            raise "Changing of visibility to #{params[:visibility]} forbidden"
          end
          handle_pending_visibility_params(params,resource,metadata_key)
        end

      end

  end
end
