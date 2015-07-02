module HydraDurham
  module AccessControlsController
    extend ActiveSupport::Concern
    include HydraDurham::VisibilityParams

    included do
      before_action :pending_visibility_handler, only: [:update]
      before_action :check_can_destroy, only: [:destroy]
    end

    private

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
