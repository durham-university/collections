require 'rdf'
require 'cgi'

class AuthoritiesController < ApplicationController
  def query
    s = params.fetch("q", "")
    hits = if params[:term] == "based_near"
      GeoNamesResource.find_location(s) rescue []
    elsif params[:term] == "subject"
      FASTResource.find_suggestions(s,'suggest50') rescue []
    elsif params[:term] == "contributor"
      NamesSolrAuthority.new.search(s) rescue []
    else
      LocalAuthority.entries_by_term(params[:model], params[:term], s) rescue []
    end
    render json: hits
  end
end
