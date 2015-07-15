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
    if obj_params[:visibility] && (obj.respond_to? :can_change_visibility?) && (!obj.can_change_visibility? obj_params[:visibility], @current_user)
      obj_params.delete :visibility
    end
    handle_pending_visibility_params obj_params, obj, :generic_file

    # params sanitisation happens here
    obj_file_params = Sufia::Forms::BatchEditForm.model_attributes(obj_params[:generic_file])

    obj.attributes = obj_file_params
    obj.date_modified = Time.now

    obj.visibility = obj_params[:visibility] if obj_params[:visibility]

    # obj.save wipes changed_attributes so we need to check this before save
    needs_notifications = needs_open_pending_notifications(obj)
    if obj.save && needs_notifications
      send_open_pending_notifications obj, @current_user
    end
  end

  def update
    case params["update_type"]
      when "update"
        batch.each do |doc_id|
          obj = ActiveFedora::Base.find(doc_id, :cast=>true)
          update_document(obj)
        end
        flash[:notice] = "Batch update complete"
        after_update
      when "delete_all"
        destroy_batch
        after_update
    end
  end

  def destroy_collection
    destroy_batch
    flash[:notice] = "Batch delete complete" if flash[:alert].blank?
    after_destroy_collection
  end

  protected

    def destroy_batch
      not_deleted=[]
      batch.each do |doc_id|
        gf = ::GenericFile.find(doc_id)
        if gf.can_destroy? @current_user
          gf.destroy
        else
          not_deleted << gf
        end
      end

      if not_deleted.any?
        if batch.length==1
          flash[:alert]="#{not_deleted[0]} is Open Access and could not be deleted."
        else
          flash[:alert]="Some of the selected files are Open Access and could not be deleted: #{(not_deleted.each &:to_s).join ', '}"
        end
      end

    end

end
