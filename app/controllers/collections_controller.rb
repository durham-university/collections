class CollectionsController < ApplicationController
  include Sufia::CollectionsControllerBehavior

  def collection_params
    form_class.model_attributes(
      params.require(:collection).permit(:title, :members, description: [], part_of: [],
        publisher: [], date_created: [], subject: [],
        language: [], resource_type: [], identifier: [], based_near: [],
        tag: [], related_url: [], funder: [], abstract: [], research_methods: [],
          contributors_attributes: [
            :id,
            :_destroy,
            {
              contributor_name: [],
              affiliation: []
            }
          ]
        )
    )
  end

  after_filter :update_datacite, only: [ :update ]
  after_filter :destroy_datacite, only: [ :destroy ]

  def update_datacite
    if @collection.manage_datacite?
      #datacite = Datacite.new
      #datacite.metadata(@collection.doi_metadata_xml)

      # Queue a job instead of sending metadata here.
      Sufia.queue.push(UpdateDataciteJob.new(@collection.id, @current_user))
    end
  end

  def destroy_datacite
    # TODO: Need to decide what happens here. Presumably something gets
    #       sent to datacite, but also need a gravestone here.
  end

  def update
    update_identifiers = collection_params[:identifier]
    if update_identifiers
      @collection.identifier.each do |id|
        if id.starts_with? "doi:#{DOI_CONFIG['doi_prefix']}/"
          if not update_identifiers.index id
            raise "Local DOI cannot be removed."
          end
        end
      end
    end
    super
  end
end
