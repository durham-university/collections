class Person < ActiveFedora::Base
	property :full_name, predicate: ::RDF::FOAF.name, multiple: false do |index|
		index.as :stored_searchable
	end
	property :orcid, predicate: ::RDF::DC.identifier, multiple: false do |index|
		index.as :stored_searchable
	end
	property :cis_username, predicate: ::RDF::FOAF.accountName, multiple: false do |index|
		index.as :stored_searchable
	end
	property :affiliation, predicate: ::RDF::FOAF.currentProject, multiple: false do |index|
		index.as :stored_searchable
	end
end