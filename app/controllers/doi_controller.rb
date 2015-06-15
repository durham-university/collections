class DoiController < ApplicationController
  # Show information related to DOI generation.
 	def show
    @id = params[:id]
    @resource = ActiveFedora::Base.find(@id)

    raise ActiveFedora::ObjectNotFoundError if not @resource
    raise "Resource doesn't support DOI functionality" if not @resource.respond_to? :doi
	end

  # Mints the doi and sends metadata to Datacite
  def mint_doi(resource)
    raise "Resource doesn't support DOI functionality" if not resource.respond_to? :doi
    raise "Resource already has a DOI" if resource.has_local_doi?

    datacite = Datacite.new
    datacite.metadata(resource.doi_metadata_xml)
    datacite.mint(resource.doi_landing_page,resource.mock_doi)
  end

  # Action that mints the doi and sends metadata to Datacite
	def update
    @id = params[:id]

    @resource = ActiveFedora::Base.find(@id)
    raise ActiveFedora::ObjectNotFoundError if not @resource

    # TODO: Permissions check! Make sure the user is allowed to publish the DOI.

    mint_doi @resource

    @resource.add_doi
    attrs = { identifier: @resource.identifier }
    if @resource.respond_to? :date_modified
      @resource.date_modified = DateTime.now
      attrs[:date_modified]=@resource.date_modified
    end
    @resource.update( attrs )

    redirect_to @resource

	end
end
