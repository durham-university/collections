require 'httparty'

class Datacite
  include HTTParty

  class DataciteUpdateException < Exception
    attr_accessor :message
    attr_accessor :body
    attr_accessor :http_code
    attr_accessor :cause
    def initialize(message,body=nil,http_code=nil,cause=nil)
      self.message=message
      self.body=body
      self.http_code=http_code
      self.cause=cause
    end

    def to_s
      "#{message} #{http_code} #{body}"
    end
  end

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
      raise DataciteUpdateException.new(response.message,response.body,response.code,response)
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
      raise DataciteUpdateException.new(response.message,response.body,response.code,response)
    end
  end
end
