class IdentifiersController < ApplicationController
  before_action :load_resource
  
  def show    
    authorize!(:show, @resource)
    path = polymorphic_path(@resource)
    path += ".#{params[:format]}" if params[:format]
    redirect_to path
  end
  
  protected
  
    def load_resource
      begin
        @resource = ActiveFedora::Base.load_instance_from_solr(params[:id])
      rescue ActiveFedora::ObjectNotFoundError => e
        @resource = ActiveFedora::Base.where(Solrizer.solr_name('identifier', :symbol) => params[:id]).first
        raise e unless @resource && (@resource.is_a?(GenericFile) || @resource.is_a?(Collection))
      end
    end
end