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

      property :creator, predicate: ::RDF::DC.creator, class_name: "Person" do |index|
        index.as :stored_searchable, :facetable
      end

      property :doi_published, predicate: ::RDF::URI.new('http://collections.durham.ac.uk/ns#doi_published'), multiple: false do |index|
        index.type :date
        index.as :stored_searchable
      end
    end
  end
end
