# -*- coding: utf-8 -*-
class GenericFilesController < ApplicationController
  include Sufia::Controller
  include Sufia::FilesControllerBehavior

  after_filter :update_datacite, only: [ :update ]
  after_filter :destroy_datacite, only: [ :destroy ]

  def update_datacite
    if @generic_file.manage_datacite?
      #datacite = Datacite.new
      #datacite.metadata(@generic_file.doi_metadata_xml)

      # Queue a job instead of sending metadata here.
      Sufia.queue.push(UpdateDataciteJob.new(@generic_file.id, @current_user))

      # TODO: Also update any collections this file may belong to?
    end
  end

  def destroy_datacite
    # TODO: Need to decide what happens here. Presumably something gets
    #       sent to datacite, but also need a gravestone here.
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

  self.presenter_class = ResourcePresenter
  self.edit_form_class = ResourceEditForm
end
