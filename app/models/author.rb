class Author < ActiveFedora::Base
  type ::RDF::FOAF.Person

  has_many :generic_files, inverse_of: :authors, class_name: "GenericFile"

  property :first_name, predicate: ::RDF::FOAF.firstName, multiple: false do |index|
    index.as :stored_searchable
  end

  property :last_name, predicate: ::RDF::FOAF.lastName, multiple: false do |index|
    index.as :stored_searchable
  end
end