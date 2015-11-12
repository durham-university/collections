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

      def contributors_sorted
        contributors.sort do |x,y| x.order.first.to_i <=> y.order.first.to_i end
      end

      def serializable_hash(*args)
        super(*args).merge({'contributors' => contributors.map(&:serializable_hash)})
      end

      def init_with_json(json)
        super(json)
        unless self.association(:contributors).loaded?
          attrs = JSON.parse(json)
          new_target = Array(attrs['contributors']).map do |c|
            Contributor.allocate.init_with_json(c.to_json)
          end

          # this would work too, and it even sets the IDs correctly, but it sends another Solr request
#          new_target = association(:contributors).load_from_solr.map do |solr_doc|
#            Contributor.allocate.init_with_json(solr_doc['object_profile_ssm'].first)
#          end

          # the target= setter wraps the target in an array for some reason so we can't use that
          self.association(:contributors).instance_variable_set(:@target,new_target)
          self.association(:contributors).loaded!
        end
        self
      end

      def to_solr(solr_doc={})
        r=super(solr_doc)
        r["contributors_tesim"]=(contributors_sorted.to_a.select do |contributor|
                !contributor.marked_for_destruction?
              end).map do |contributor|
                contributor.to_s
              end
        r["contributors_sim"]=r["contributors_tesim"] # this is needed for facets
        r
      end
    end
  end
end
