class BatchEditsController < ApplicationController
  include Hydra::BatchEditBehavior
  include GenericFileHelper
  include Sufia::BatchEditsControllerBehavior
  include HydraDurham::VisibilityParams

  def edit
     @generic_file = ::GenericFile.new
     @generic_file.depositor = current_user.user_key
     @terms = terms - [:title, :format, :resource_type, :identifier, :publisher]

     h  = {}
     @names = []
     permissions = []

     # For each of the files in the batch, set the attributes to be the concatination of all the attributes
     batch.each do |doc_id|
        gf = ::GenericFile.load_instance_from_solr(doc_id)
        terms.each do |key|
          h[key] ||= []
          h[key] = (h[key] + gf.send(key)).uniq
        end
        @names << gf.to_s
        permissions = (permissions + gf.permissions).uniq
     end

     initialize_fields(h, @generic_file)

     @generic_file.permissions_attributes = [{type: 'group', name: 'public', access: 'read'}]
  end

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
    obj_file_params = obj_file_params.except(:identifier, :publisher)

    obj.attributes = obj_file_params
    obj.date_modified = Time.now

    obj.visibility = obj_params[:visibility] if obj_params[:visibility]

    # obj.save wipes changed_attributes so we need to check this before save
    needs_notifications = needs_open_pending_notifications(obj)

    saved=obj.save

    if saved and obj.respond_to? :doi
      # Queue method checks that the object has a local doi.
      # It will also push metadata updates on any dependent documents.
      obj.queue_doi_metadata_update @current_user
    end

    if saved && needs_notifications
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

    def initialize_fields(attributes, file)
       terms.each do |key|
         # if value is empty, we create an one element array to loop over for output
         file[key] = if attributes[key].empty?
           if key==:contributors
             [Contributor.new]
           else
             ['']
           end
         else
           attributes[key]
         end
       end
    end


    def destroy_batch
      not_deleted=[]
      batch.each do |doc_id|
        gf = ::GenericFile.find(doc_id)
        if gf.can_destroy? @current_user
          if gf.respond_to? :doi
            # Queue method checks that the object has a local doi.
            # It will also push metadata updates on any dependent documents.
            gf.queue_doi_metadata_update @current_user, destroyed: true
          end
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
