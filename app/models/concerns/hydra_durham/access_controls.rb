module HydraDurham
  module AccessControls
    extend ActiveSupport::Concern
    include Hydra::AccessControls::WithAccessRight
    include HydraDurham::VisibilityParams

    included do
      property :request_for_visibility_change, predicate: ::RDF::URI.new('http://collections.durham.ac.uk/ns#request_for_access_change'), multiple: false

      validates :request_for_visibility_change, acceptance: { accept: Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC }
    end

    # Check if the document is in the state of open access pending.
    def open_access_pending?
      !open_access? && request_for_visibility_change==Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC
    end

    # This only checks if a doi can be minted based no the visibility of the
    # document. It does not check if a DOI already exists or if one cannot be
    # minted for any other reasons.
    def can_mint_doi?
      open_access?
    end

    # Alias for can_destoy?
    def can_delete?(user=nil)
      can_destroy?(user)
    end

    # Checks if the document can be deleted based on its visibility and what
    # the user is allowed to do with documents of that visibility. Does not
    # factor in anything else about the document or if the user in general
    # has rights to edit this document.
    def can_destroy?(user=nil)
      return false if user.nil?
      return true if user.admin?
      return visibility!=Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC
    end

    # Checks if the visibility fo the document can be changed by the given
    # user. The check is only based on the current visibility and the role
    # of the user. Does not check if the user has general edit rights to
    # edit the document or anything else about the document.
    def can_change_visibility?(new_visibility,user=nil)
      case new_visibility
      when Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC
        return open_access? || (user && user.admin?)
      when 'open-pending'
        return !open_access? || (user && user.admin?)
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
