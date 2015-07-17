class DoiController < ApplicationController
  # Show information related to DOI generation.
   def show
    @id = params[:id]
    @resource = ActiveFedora::Base.find(@id)

    raise ActiveFedora::ObjectNotFoundError if not @resource
    raise "Resource doesn't support DOI functionality" if not @resource.respond_to? :doi

    @metadata_errors = @resource.validate_doi_metadata

    if @resource.is_a? Collection
      @presenter = Sufia::CollectionPresenter.new @resource
      @model_class = "collection"
    else
      @presenter = Sufia::GenericFilePresenter.new @resource
      @model_class = "generic_file"
    end
  end

  # Mints the doi and sends metadata to Datacite
  def mint_doi(resource)
    raise "Resource doesn't support DOI functionality" if not resource.respond_to? :doi
    raise "Resource already has a DOI" if resource.has_local_doi?
    raise "Cannot mint DOI for this resource" if (resource.respond_to? :can_mint_doi?) && !resource.can_mint_doi?

    #datacite = Datacite.new
    #datacite.metadata(resource.doi_metadata_xml)
    #datacite.mint(resource.doi_landing_page,resource.mock_doi)

    resource.queue_doi_metadata_update @current_user, mint: true
  end

  # Action that mints the doi and sends metadata to Datacite
  def update
    @id = params[:id]
    @resource = ActiveFedora::Base.find(@id)
    raise ActiveFedora::ObjectNotFoundError if not @resource

    authorize! :edit, @resource

    raise "Resource doesn't support DOI functionality" if not @resource.respond_to? :doi
    raise "Cannot mint DOI for this resource" if (@resource.respond_to? :can_mint_doi?) && !@resource.can_mint_doi?

    errors = @resource.validate_doi_metadata
    if errors.any?
      raise RuntimeError.new(errors.join('\n'))
    end

    mint_doi @resource

    redirect_to @resource

  end
end
