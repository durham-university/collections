module Sufia
  module Forms
    class BatchEditForm < GenericFileEditForm
      self.terms -= [:identifier]
    end
  end
end