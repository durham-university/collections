class AddUseLabelToLocalAuthorityEntries < ActiveRecord::Migration
  def change
    add_column :local_authority_entries, :use_label, :string
  end
end
