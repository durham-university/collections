module HydraDurham
  module DoiResourceBehaviour
    extend ActiveSupport::Concern

    included do
      before_filter :restrict_local_doi_changes, only: [ :update ]
      after_filter :update_datacite, only: [ :update ]
      after_filter :destroy_datacite, only: [ :destroy ]
    end

    def update_datacite
      resource=@resource || instance_variable_get("@#{controller_name.singularize}")
      # queue_doi_metadata_update makes sure that this resource has a local doi and needs a datacite update
      resource.queue_doi_metadata_update @current_user
    end

    def destroy_datacite
      resource=@resource || instance_variable_get("@#{controller_name.singularize}")
      # queue_doi_metadata_update makes sure that this resource has a local doi and needs a datacite update
      resource.queue_doi_metadata_update @current_user, destroyed: true
    end

    def identifier_params
      # This method gets the identifiers sent as parameters for the update action.
      # It tries to handle both GenericFile and Collection and maybe any future
      # model that behaves in a similar way. But it can also be overridden in any
      # future model if needed.

      if respond_to? :edit_form_class
        # GenericFile
        return edit_form_class.model_attributes(params[controller_name.singularize.to_sym])[:identifier]
      else
        # Collection
        params_method="#{controller_name.singularize}_params".to_sym
        if respond_to? params_method
          return (send params_method)[:identifier]
        end
      end
      return nil
    end

    def restrict_local_doi_changes
      update_identifiers=identifier_params
      if update_identifiers
        resource=@resource || instance_variable_get("@#{controller_name.singularize}")

        had_local=resource.has_local_doi?
        will_have_local=resource.has_local_doi? update_identifiers

        raise "Local DOI cannot be removed" if had_local && !will_have_local
        raise "Local DOI cannot be added" if !had_local && will_have_local
      end
    end


  end
end
