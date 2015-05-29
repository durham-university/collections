class ResourceEditForm < ResourcePresenter
  include HydraEditor::Form
  include HydraEditor::Form::Permissions

  self.required_fields = [:title]

  protected
    def self.build_permitted_params
      permitted = super
      permitted.delete({ authors: [] })
      permitted << { authors_attributes: permitted_authors_params }
      permitted
    end

    def self.permitted_authors_params
      [ 
        :id, 
        :_destroy, 
        {
          first_name: [],
          last_name: []
        },
        :orcid
      ]
    end

    # Override HydraEditor::Form to treat nested attributes accordingly
    def initialize_field(key)
      if reflection = model_class.reflect_on_association(key)
        raise ArgumentError, "Association ''#{key}'' is not a collection" unless reflection.collection?
        build_association(key)
      else
        super
      end
    end

  private

    def build_association(key)
      association = model.send(key)
      if association.empty?
        self[key] = Array(association.build)
      else
        association.build
        self[key] = association
      end
    end
end