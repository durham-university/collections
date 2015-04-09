class DoiController < ApplicationController
  def show
   	@id = params[:id]
   	@resource = ActiveFedora::Base.find(@id)
  end
end
