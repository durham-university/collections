module Sufia
  module Forms
    class GenericFileEditForm < GenericFilePresenter
      include HydraEditor::Form
      include HydraDurham::FormContributorOverrides
      include HydraEditor::Form::Permissions

      # These cannot be done using validators because batch edits require blank
      # data to be saved in the database.
      self.required_fields = [:title, :contributors, :tag, :rights, :resource_type]
    end
  end
end
