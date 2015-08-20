require 'rails_helper'

RSpec.describe DoiController, type: :controller do

  let(:user) { FactoryGirl.find_or_create(:registered_user_1) }
  let(:other_user) { FactoryGirl.find_or_create(:registered_user_2) }
  let(:file) { FactoryGirl.create(:generic_file, depositor: user) }
  let(:public_file) { FactoryGirl.create(:public_file, depositor: user) }
  let(:collection) { FactoryGirl.create(:collection, depositor: user) }

  describe "GET #show" do
    context "when not logged in" do
      it "not allowed to view the resource" do
        get :show, id: file.id
        expect(response).not_to have_http_status(:success)
      end
    end

    context "when logged in as someone else" do
      before { sign_in other_user }
      it "not allowed to view the resource" do
        get :show, id: file.id
        expect(response).not_to have_http_status(:success)
      end
    end

    context "when logged in" do
      before { sign_in user }

      it "returns http success for a file" do
        get :show, id: file.id
        expect(response).to have_http_status(:success)
      end

      it "returns http success for a collection" do
        get :show, id: collection.id
        expect(response).to have_http_status(:success)
      end

      it "sets model_class for a file" do
        get :show, id: file.id
        expect(assigns(:model_class)).to eql('generic_file')
      end

      it "sets model_class for a collection" do
        get :show, id: collection.id
        expect(assigns(:model_class)).to eql('collection')
      end

      context "with invalid file" do
        # the file is already missing some mandatory fields
        it "assigns metadata_errors" do
          get :show, id: file.id
          expect(assigns(:metadata_errors)).not_to be_empty
        end
      end

      context "with valid file" do
        before {
          file.title=['Title']
          file.resource_type=['Image']
          file.contributors=[FactoryGirl.build(:contributor,
                                  contributor_name: ['Contributor 1'],
                                  affiliation: ['Affiliation 1'],
                                  role: ['http://id.loc.gov/vocabulary/relators/cre'])]
          file.visibility=Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC
          file.save
        }

        it "sets empty metadata_errors" do
          get :show, id: file.id
          expect(assigns(:metadata_errors)).to be_empty
        end
      end

    end

  end

  describe "GET #update" do
    context "with valid file" do
      before {
        file.title=['Title']
        file.resource_type=['Image']
        file.contributors=[FactoryGirl.build(:contributor,
                                contributor_name: ['Contributor 1'],
                                affiliation: ['Affiliation 1'],
                                role: ['http://id.loc.gov/vocabulary/relators/cre'])]
        file.visibility=Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC
        file.save
      }

      context "when not logged in" do
        it "not allowed to view the resource" do
          expect(Sufia.queue).not_to receive(:push).with(UpdateDataciteJob)
          get :update, id: file.id
          expect(response).to redirect_to(root_path)
        end
      end

      context "when logged in as someone else" do
        before { sign_in other_user }
        it "not allowed to view the resource" do
          expect(Sufia.queue).not_to receive(:push).with(UpdateDataciteJob)
          get :update, id: file.id
          expect(response).to redirect_to(root_path)
        end
      end

      context "when logged in" do
        before { sign_in user }

        it "returns http success" do
          expect(Sufia.queue).to receive(:push).with(UpdateDataciteJob).once
          get :update, id: file.id
          expect(response).to redirect_to(generic_file_path(file.id))
        end
      end
    end

    context "with invalid file" do |variable|
      before { sign_in user }

      it "raises an error" do
        expect(Sufia.queue).not_to receive(:push).with(UpdateDataciteJob)
        expect { get :update, id: file.id }.to raise_error
      end
    end
  end

end
