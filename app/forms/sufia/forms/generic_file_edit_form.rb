module Sufia
  module Forms
    class GenericFileEditForm < GenericFilePresenter
      include HydraEditor::Form
      include HydraEditor::Form::Permissions
      self.required_fields = [:title, :rights]

      def self.build_permitted_params
        permitted=super
        permitted << :request_for_visibility_change
        permitted
      end
    end
  end
end
