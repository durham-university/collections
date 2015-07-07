# -*- coding: utf-8 -*-
class GenericFilesController < ApplicationController
  include Sufia::Controller
  include Sufia::FilesControllerBehavior

  after_filter :update_datacite, only: [ :update ]
  after_filter :destroy_datacite, only: [ :destroy ]

  def update_datacite
    # queue_doi_metadata_update makes sure that this file has a local doi and needs a datacite update
    @generic_file.queue_doi_metadata_update @current_user
  end

  def destroy_datacite
    # queue_doi_metadata_update makes sure that this file has a local doi and needs a datacite update
    @generic_file.queue_doi_metadata_update @current_user, destroyed: true
  end

  def update
    if params[:generic_file]
      update_identifiers = edit_form_class.model_attributes(params[:generic_file])[:identifier]
      if update_identifiers
        local_doi=@generic_file.full_mock_doi.downcase
        @generic_file.identifier.each do |id|
          if id==local_doi && !update_identifiers.index(id)
            raise "Local DOI cannot be removed."
          end
        end
      end
    end
    super
  end
end
