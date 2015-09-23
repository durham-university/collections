class Collection < Sufia::Collection
  include HydraDurham::Metadata
  include HydraDurham::Doi

  # title validation already in hydra-collection
  validates :contributors, presence: true
  validates :tag, presence: true
  validates :resource_type, presence: true
  validates :resource_type, acceptance: { allow_nil: false, accept: ['Collection'] }

  def self.ingest_doi(id, map, depositor)
  	begin 
  		c = Collection.new(id:id.to_s.downcase)
  	rescue ActiveFedora::IllegalOperation => e
  		puts "Object #{id} #{map[:date_created]} already exists"
  		return
  	end
  	
  	c.attributes = map
  	c.resource_type = ['Collection']
	c.apply_depositor_metadata(depositor)
  	c.save!

  	# puts c.to_solr
  end
end
