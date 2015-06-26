module HydraDurham
  module AccessControls
    extend ActiveSupport::Concern
    include Hydra::AccessControls::WithAccessRight

    included do
      property :request_for_visibility_change, predicate: ::RDF::URI.new('http://collections.durham.ac.uk/ns#request_for_access_change'), multiple: false
    end

    def open_access_pending?
      !open_access? && request_for_visibility_change==Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC
    end

    def can_change_visibility?(new_visibility,user=nil)
      case new_visibility
      when Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC
        return open_access? || (user && user.admin?)
      when 'open-pending'
        return !open_access?
      when Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_AUTHENTICATED
        return !open_access? || (user && user.admin?)
      when Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE
        return !open_access? || (user && user.admin?)
      else
        return false
      end
    end
  end
end
