module HydraDurham
  module DoiResourceBehaviour
    extend ActiveSupport::Concern

    included do
      before_filter :set_resource_doi_override, only: [ :edit, :update ]
      before_filter :restrict_local_doi_changes, only: [ :update ]
      before_filter :restrict_published_doi_deletion, only: [ :destroy ]
    end

    def identifier_params
      # This method gets the new identifiers sent as parameters for the update action.
      # It tries to handle both GenericFile and Collection and maybe any future
      # model that behaves in a similar way. But it can also be overridden in any
      # future model if needed.

      if respond_to? :edit_form_class
        # GenericFile
        controller_sym=controller_name.singularize.to_sym
        return nil if !(params.key? controller_sym)
        return edit_form_class.model_attributes(params[controller_sym])[:identifier]
      else
        # Collection
        params_method="#{controller_name.singularize}_params".to_sym
        if respond_to? params_method
          return (send params_method)[:identifier]
        end
      end
      return nil
    end

    def set_resource_doi_override
      resource=@resource || instance_variable_get("@#{controller_name.singularize}")
      resource.doi_protection_override! if current_user.try(:admin?)
    end

    def restrict_local_doi_changes
      # Don't let any doi identifier changes be made through this controller.
      # Model has validation for other restricted fields.

      update_identifiers=identifier_params
      if update_identifiers
        resource=@resource || instance_variable_get("@#{controller_name.singularize}")

        return if resource.doi_protection_override?

        had_local=resource.has_local_doi?
        will_have_local=resource.has_local_doi? update_identifiers

        raise "Local DOI cannot be removed" if had_local && !will_have_local
        raise "Local DOI cannot be added" if !had_local && will_have_local
      end
    end

    def restrict_published_doi_deletion
      resource=@resource || instance_variable_get("@#{controller_name.singularize}")
      raise "Cannot delete resource with a published local DOI" if resource.has_local_doi?
    end

  end
end
