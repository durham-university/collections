module Sufia
  module Forms
    class GenericFileEditForm < GenericFilePresenter
      include HydraEditor::Form
      include HydraDurham::FormAuthorOverrides
      include HydraEditor::Form::Permissions

      self.required_fields = [:title, :rights]
    end
  end
end
