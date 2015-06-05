require 'rdf'
require 'cgi'

class AuthoritiesController < ApplicationController
  def query
    s = params.fetch("q", "")
    hits = if params[:term] == "location"
      GeoNamesResource.find_location(s)
    elsif params[:term] == "subject"
      FASTResource.find_suggestions(s,'suggest50') rescue []
    else
      LocalAuthority.entries_by_term(params[:model], params[:term], s) rescue []
    end
    render json: hits
  end
end
