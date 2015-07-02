module HydraDurham
  module VisibilityParams
    extend ActiveSupport::Concern

    def handle_pending_visibility_params(params,resource,metadata_key)
      # NOTE: params usually has not been sanitised, be careful!
      if params[:visibility]=='open-pending'
        params.delete :visibility
        params[metadata_key]||=ActionController::Parameters.new()
        params[metadata_key][:request_for_visibility_change]=Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC
      elsif params[:visibility]
        params[metadata_key]||=ActionController::Parameters.new()
        params[metadata_key][:request_for_visibility_change]=nil
      end
    end

  end
end
