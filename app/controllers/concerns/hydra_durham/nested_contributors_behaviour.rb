module HydraDurham
  module NestedContributorsBehaviour
    extend ActiveSupport::Concern

    included do
      before_filter :deserialise_contributor_affiliations, only: [ :update, :create ]
    end

    private
      def deserialise_contributor_affiliations
        controller_key=controller_name.singularize

        controller_key='generic_file' if controller_key=='batch_edit' || controller_key=='batch'

        if params.key?(controller_key) && params[controller_key].key?('contributors_attributes')
          contributors_attributes = params[controller_key]['contributors_attributes']
          values = contributors_attributes.is_a?(Hash) ? contributors_attributes.values : contributors_attributes
          values.each do |c|
            if c.key?('affiliation')
              (c['affiliation'].map! do |affiliation|
                affiliation.strip.split(/\s*;\s*/).select(&:present?)
              end).flatten!.compact!
            end
            if c.key?('role')
              c['role'].map!(&:strip).select!(&:present?)
            end
          end
        end
      end
  end
end
