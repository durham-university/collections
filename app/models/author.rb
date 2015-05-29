class Author < ActiveFedora::Base
  type ::RDF::DC.Agent

  has_many :generic_files, inverse_of: :authors, class_name: "GenericFile"

  property :first_name, predicate: ::RDF::FOAF.firstName, multiple: false do |index|
    index.as :stored_searchable
  end

  property :last_name, predicate: ::RDF::FOAF.lastName do |index|
    index.as :stored_searchable
  end

  property :orcid, predicate: ::RDF::RDFS.label do |index|
    index.as :stored_searchable
  end
end