module HydraDurham
  module AccessControlsController
    extend ActiveSupport::Concern

    included do
      before_action :check_can_change_visibility, only: [:update]
      before_action :check_can_destroy, only: [:destroy]
    end

    private

      def check_can_destroy
        resource=@resource || instance_variable_get("@#{controller_name.singularize}")
        user=@current_user || nil
        raise "Deleting resource forbidden" if not resource.can_destroy? user
      end

      def check_can_change_visibility
        resource=@resource || instance_variable_get("@#{controller_name.singularize}")
        user=@current_user || nil

        if params[:visibility]
          metadata_key=controller_name.singularize.to_sym

          if not resource.can_change_visibility? params[:visibility], user
            raise "Changing of visibility to #{params[:visibility]} forbidden"
          end
          if params[:visibility]=='open-pending'
            params.delete :visibility
            params[metadata_key]={} unless params.key? metadata_key
            params[metadata_key][:request_for_visibility_change]=Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC
          elsif params[:visibility]!=resource.visibility
            params[metadata_key]={} unless params.key? metadata_key
            params[metadata_key][:request_for_visibility_change]=nil
          end
        end

      end

  end
end
