# -*- coding: utf-8 -*-
class GenericFilesController < ApplicationController
  include Sufia::Controller
  include Sufia::FilesControllerBehavior
  include HydraDurham::DoiResourceBehaviour
  include HydraDurham::AccessControlsController
  include HydraDurham::NestedContributorsBehaviour

  def update
    super
    if self.status==302 && self.location && self.location.start_with?(sufia.edit_generic_file_url(@generic_file)) # && !self.location.ends_with?('tab=permissions') && !self.location.ends_with?('tab=versions')
      self.response_body=nil
      redirect_to sufia.generic_file_path(@generic_file)
    end
  end
end
