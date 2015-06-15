require 'httparty'

class Datacite
  include HTTParty

  def initialize
    @auth = {:username => Rails.application.secrets.mduser, :password => Rails.application.secrets.mdpassword}
    if Rails.env.production? then
      self.class.base_uri 'https://mds.datacite.org'
      @api_doi_path = '/doi'
      @api_metadata_path = '/metadata'
    else #development/test
      self.class.base_uri 'https://test.datacite.org'
      @api_doi_path = '/mds/doi'
      @api_metadata_path = '/mds/metadata'
    end
  end

  # mint DOI
  def mint(url, doi)
    options = { :body => "doi=#{doi}\nurl=#{url}",
                :basic_auth => @auth,
                :headers => {'Content-Type' => 'text/plain'} }
    response = self.class.post(@api_doi_path, options)
    if response.success?
      response
    else
      raise response.response
    end
  end

  # register metadata
  def metadata(xml)
    options = { :body => xml, :basic_auth => @auth,
                :headers => {'Content-Type' => 'application/xml;charset=UTF-8'} }
    response = self.class.post(@api_metadata_path, options)
    if response.success?
      response
    else
      raise response.response
    end
  end
end
