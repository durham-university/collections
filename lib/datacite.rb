require 'httparty'

class Datacite
  include HTTParty
  base_uri 'https://test.datacite.org'
  # PRODUCTION # base_uri 'https://mds.datacite.org'

  def initialize
    @auth = {:username => Rails.application.secrets.mduser, :password => Rails.application.secrets.mdpassword}
  end

  # mint DOI
  def mint(url, doi)
    options = { :body => "doi=#{doi}\nurl=#{url}", 
                :basic_auth => @auth, 
                :headers => {'Content-Type' => 'text/plain'} }
    puts options
    self.class.post('/mds/doi', options)
    # PRODUCTION # self.class.post('/doi', options)
  end
  
  # register metadata
  def metadata(xml)
    options = { :body => xml, :basic_auth => @auth, 
                :headers => {'Content-Type' => 'application/xml;charset=UTF-8'} }
    self.class.post('/mds/metadata', options)
    # PRODUCTION # self.class.post('/metadata', options)
  end
end