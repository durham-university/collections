class CollectionsController < ApplicationController
  include Sufia::CollectionsControllerBehavior
  include HydraDurham::DoiResourceBehaviour

  def collection_params
    form_class.model_attributes(
      params.require(:collection).permit(:title, :description, :members, part_of: [],
        publisher: [], date_created: [], subject: [],
        language: [], rights: [], resource_type: [], identifier: [], based_near: [],
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

end
