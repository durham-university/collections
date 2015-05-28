require 'rails_helper'

describe GenericFile do

  let(:file) do
    GenericFile.create do |f|
      f.apply_depositor_metadata "user"
    end
  end

  describe "setting the title" do
    before { file.title = ["My Favorite Things"] }
    subject { file.title}
    it { is_expected.to eql ["My Favorite Things"] }
  end

  describe "adding an author" do
    before { file.authors_attributes = [{first_name: "John", last_name: "Coltrane"}] }
    subject { file.authors.first }
    it { is_expected.to be_kind_of Author }
  end
end