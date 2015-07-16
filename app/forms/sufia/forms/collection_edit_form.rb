module Sufia
  module Forms
    class CollectionEditForm
      include HydraEditor::Form
      include HydraDurham::FormContributorOverrides

      self.model_class = ::Collection
      self.terms = [:resource_type, :title, :contributors,
                  :funder, :abstract, :research_methods,
                  :description, :tag, :subject, :based_near, :language,
                  :related_url, :identifier,
                  :publisher, :date_created ]

      # Test to see if the given field is required
      # @param [Symbol] key a field
      # @return [Boolean] is it required or not
      def required?(key)
        model_class.validators_on(key).any?{|v| v.kind_of? ActiveModel::Validations::PresenceValidator}
      end

      def self.build_permitted_params
        permitted=super
        permitted << :request_for_visibility_change
        permitted
      end
    end
  end
end
