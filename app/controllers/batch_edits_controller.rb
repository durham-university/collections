class BatchEditsController < ApplicationController
   include Hydra::BatchEditBehavior
   include GenericFileHelper
   include Sufia::BatchEditsControllerBehavior
   include HydraDurham::VisibilityParams

   def update_document(obj)
     # Duplicate the params for each document since we're going to have
     # to make small changes to them on a per document basis.
     # NOTE: params and hence obj_params is not sanitised !!
     obj_params = params.deep_dup
     obj_params[:generic_file] ||= ActionController::Parameters.new()

     # If the user isn't allowed to change the visibility of this file
     # just remove the visibility param
     if obj_params[:visibility] && (obj.respond_to? :can_change_visibility?) && (!obj.can_change_visibility? obj_params[:visibility])
       obj_params.delete :visibility
     end
     handle_pending_visibility_params obj_params, obj, :generic_file

     # params sanitisation happens here
     obj_file_params = Sufia::Forms::BatchEditForm.model_attributes(obj_params[:generic_file])

     obj.attributes = obj_file_params
     obj.date_modified = Time.now

     obj.visibility = obj_params[:visibility] if obj_params[:visibility]
   end

end
