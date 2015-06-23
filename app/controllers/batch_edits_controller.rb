class BatchEditsController < ApplicationController
  include Hydra::BatchEditBehavior
  include GenericFileHelper
  include Sufia::BatchEditsControllerBehavior

  def edit
     super
     @generic_file = ::GenericFile.new
     @generic_file.depositor = current_user.user_key
     @terms = terms - [:title, :format, :resource_type, :identifier]

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
    obj.attributes = generic_file_params.except(:identifier)
    obj.date_modified = Time.now.ctime
    obj.visibility = params[:visibility]
    # TODO: trigger DOI updates here
  end

  def destroy_batch
    # TODO: trigger DOI updates here
    super
  end
end
