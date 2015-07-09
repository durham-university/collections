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

      has_many :contributors, inverse_of: :contributorable, as: 'contributorable'

      accepts_nested_attributes_for :contributors, allow_destroy: true, reject_if: proc { |attributes| attributes['contributor_name'].first.blank? }

      def to_solr(solr_doc={})
        r=super(solr_doc)
        r["contributors_tesim"]=(contributors.to_a.select do |contributor| !contributor.marked_for_destruction? end)
                                             .map do |contributor| contributor.to_s end
        r["contributors_sim"]=r["contributors_tesim"] # this is needed for facets
        r
      end
    end
  end
end
