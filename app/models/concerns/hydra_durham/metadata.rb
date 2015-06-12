module HydraDurham
  module Metadata
    extend ActiveSupport::Concern

    included do
      property :funder, predicate: ::RDF::URI.new('http://collections.durham.ac.uk/ns#funder') do |index|
        index.as :stored_searchable, :facetable
      end

      property :abstract, predicate: ::RDF::DC.abstract do |index|
        index.type :text
        index.as :stored_searchable
      end

      property :research_methods, predicate: ::RDF::URI.new('http://collections.durham.ac.uk/ns#methods') do |index|
        index.type :text
        index.as :stored_searchable
      end

      property :doi_published, predicate: ::RDF::URI.new('http://collections.durham.ac.uk/ns#doi_published'), multiple: false do |index|
        index.type :date
        index.as :stored_searchable
      end

      has_and_belongs_to_many :authors, predicate: ::RDF::DC.creator, class_name: "Author", inverse_of: :generic_files

      accepts_nested_attributes_for :authors, allow_destroy: true
    end
  end
end
