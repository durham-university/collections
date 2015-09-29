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

  # Fetch DOI metadata from DataCite XML file
  def self.get_data(doi,prefix=nil)
    prefix ||= DOI_CONFIG['fetch_doi_prefix']
    url = "http://data.datacite.org/application/x-datacite+xml/#{prefix}/#{doi}"
    response = HTTParty.get(url)

    xml = Nokogiri::XML( response.body )
    xml.remove_namespaces!
    resource = xml % "resource"

    titles = resource.xpath("//resource/titles/title").map do |title|
      title.inner_html
    end

    order = -1
    creators = resource.xpath("//resource/creators/creator").map do |creator|
      order += 1
      {contributor_name: [creator.xpath('creatorName').inner_html],
       affiliation: [creator.xpath('affiliation').inner_html],
       role: ['http://id.loc.gov/vocabulary/relators/cre'],
       order: ["#{order}"]}
    end

    contributors = resource.xpath("//resource/contributors/contributor[@contributorType='ContactPerson']").map do |contributor|
      if contributor.xpath('affiliation').count != 0
        affiliation = contributor.xpath('affiliation').inner_html
      else
        affiliation = DOI_CONFIG['fetch_affiliation']
      end
      order += 1
      {contributor_name: [contributor.xpath('contributorName').inner_html],
       affiliation: [affiliation],
       role: ['http://id.loc.gov/vocabulary/relators/mdc'],
       order: ["#{order}"]}
    end

    funders = resource.xpath("//resource/contributors/contributor[@contributorType='Funder']").map do |funder|
      funder.xpath('contributorName').inner_html
    end

    subjects = resource.xpath("//resource/subjects/subject").map do|subject|
      subject.inner_html
    end

    relatedIdentifiers = resource.xpath("./relatedIdentifiers/relatedIdentifier").map do |relatedIdentifier|
      relatedIdentifier.inner_html
    end

    abstracts = resource.xpath("//resource/descriptions/description[@descriptionType='Abstract']").map do |abstract|
      abstract.inner_html
    end

    descriptions = resource.xpath("//resource/descriptions/description[@descriptionType='Other']").map do |description|
      description.inner_html
    end

    methods = resource.xpath("//resource/descriptions/description[@descriptionType='Methods']").map do |method|
      methods.inner_html
    end

    return {
          title: titles,
          tag: subjects,
          contributors_attributes: creators+contributors,
          related_url: relatedIdentifiers,
          abstract: abstracts,
          description: descriptions,
          research_methods: methods,
          funder: funders
        }
  end

end
