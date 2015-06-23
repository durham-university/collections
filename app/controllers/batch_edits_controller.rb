class BatchEditsController < ApplicationController
  include Hydra::BatchEditBehavior
  include GenericFileHelper
  include Sufia::BatchEditsControllerBehavior

  def edit
     super
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
    obj.attributes = generic_file_params.except(:identifier, :publisher)
    obj.date_modified = Time.now
    obj.visibility = params[:visibility]

    saved=obj.save

    if saved and obj.respond_to? :doi and obj.manage_datacite?
      obj.queue_doi_metadata_update
    end
  end

  def update
    batch.each do |doc_id|
      obj = ActiveFedora::Base.find(doc_id, :cast=>true)
      update_document(obj)
    end
    flash[:notice] = "Batch update complete"
    after_update
  end

  def destroy_batch
    batch.each do |doc_id|
      gf = ::GenericFile.find(doc_id)
      if gf.respond_to? :doi and gf.manage_datacite?
        gf.queue_doi_metadata_update(destroyed: true)
      end
      gf.destroy
    end
    after_update
  end

end
