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

      has_many :authors, inverse_of: :authorable

      accepts_nested_attributes_for :authors, allow_destroy: true, reject_if: proc { |attributes| attributes['author_name'].first.blank? }

      def to_solr(solr_doc={})
        r=super(solr_doc)
        r["authors_tesim"]=authors.map do |author| author.to_s end
        r["authors_sim"]=r["authors_tesim"] # this is needed for facets
        r
      end
    end
  end
end
