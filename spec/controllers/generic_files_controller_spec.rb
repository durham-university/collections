require 'rails_helper'

describe GenericFilesController do
  routes { Sufia::Engine.routes }
  let(:user) { FactoryGirl.find_or_create(:user) }
  before { sign_in user }

  describe "update" do
    let(:generic_file) do
      GenericFile.create do |gf|
        gf.apply_depositor_metadata(user)
      end
    end

    context "when adding a title" do
      let(:attributes) { { title: ['My Favorite Things'] } }
      before { post :update, id: generic_file, generic_file: attributes }
      subject do
        generic_file.reload.title
      end
      it { is_expected.to eq ["My Favorite Things"] }
    end

    context "when adding an author" do
      let(:attributes) do
        { 
          title: ['My Favorite Things'], 
          authors_attributes: [{ first_name: 'John', last_name: 'Coltrane' }],
          permissions_attributes: [{ type: 'person', name: 'archivist1', access: 'edit'}]
        }
      end

      before { post :update, id: generic_file, generic_file: attributes }
      subject { generic_file.reload }

      it "sets the values using the parameters hash" do
        expect(subject.authors.first.first_name).to eq "John"
        expect(subject.authors.first.last_name).to eq "Coltrane"
      end
    end
  end
end