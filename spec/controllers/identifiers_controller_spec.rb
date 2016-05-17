require 'rails_helper'

RSpec.describe IdentifiersController, type: :controller do

  let(:user) { FactoryGirl.find_or_create(:registered_user_1) }
  let(:other_user) { FactoryGirl.find_or_create(:registered_user_2) }
  let(:file) { FactoryGirl.create(:generic_file, depositor: user, identifier: ['ark:/12345/r9ab12cd34efx']) }
  let(:public_file) { FactoryGirl.create(:public_file, depositor: user, identifier: ['ark:/12345/r8ab12cd34efx']) }

  describe "GET #show" do
    context "with anonymous user" do
      it "redirects arks to public files" do
        get :show, id: public_file.identifier.first
        expect(response).to redirect_to(generic_file_path(public_file))
      end
      it "doesn't redirect arks to private files" do
        get :show, id: file.identifier.first
        expect(response.code).not_to redirect_to(generic_file_path(file))
      end
    end
    context "with singed in user" do
      before { sign_in user }
      it "redirects to user's private files" do
        get :show, id: file.identifier.first
        expect(response).to redirect_to(generic_file_path(file))
      end
    end
  end
  
end