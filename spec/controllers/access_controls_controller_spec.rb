require 'rails_helper'

RSpec.describe "access_controls_controller" do
  let(:user) { FactoryGirl.find_or_create(:registered_user_1) }
  let(:other_user) { FactoryGirl.find_or_create(:registered_user_2) }
  before { sign_in user }

  let(:file_attributes) {
    {
      title: ['Test title'],
      identifier: ['isbn:123456', 'arXiv:0123.0000', 'http://something.else.com'],
      abstract: ['Test abstract'],
      research_methods: ['Test research method 1', 'Test research method 2'],
      funder: ['Funder 1'],
      tag: ['keyword1', 'keyword2'],
      subject: ['subject1', 'subject2'],
      related_url: ['http://related.url.com/test'],
      description: ['Description'],
      resource_type: ['Image'],
      date_uploaded: DateTime.parse('Thu, 16 Jul 2015 12:44:38 +0100'),
      rights: ['http://creativecommons.org/licenses/by-nc-sa/4.0/']
    }
  }
  let(:user) { FactoryGirl.find_or_create(:registered_user_1) }

  let(:private_file) { FactoryGirl.create(:generic_file, depositor: user) }
  let(:registered_file) { FactoryGirl.create(:registered_file, depositor: user) }
  let(:public_file) { FactoryGirl.create(:public_file, depositor: user) }
  let(:pending_file) {
    FactoryGirl.create(:registered_file, depositor: user) do |file|
      file.request_for_visibility_change = Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC
    end
  }
  let(:other_private_file) { FactoryGirl.create(:generic_file, depositor: other_user) }

  describe GenericFilesController do
    routes { Sufia::Engine.routes }

    describe "can_destroy" do
      context "private file" do
        let!(:file) { private_file }
        it "should let delete the file" do
          expect {
            post :destroy, id: file.id
          }.not_to raise_error
          expect( GenericFile.where(id: file.id).to_a ).to be_empty
        end
      end
      context "public file" do
        let!(:file) { public_file }
        it "should not let delete the file" do
          expect {
            post :destroy, id: file.id
          }.to raise_error("Deleting resource forbidden")
          expect( GenericFile.where(id: file.id).to_a ).not_to be_empty
        end
      end
    end

    describe "pending_visibility_handler" do
      describe "private file" do
        let!(:file) { private_file }

        context "changing to public" do
          it "should not be allowed" do
            expect {
              post :update, id: file.id, visibility: Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC
            }.to raise_error("Changing of visibility to #{Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC} forbidden")
            expect( file.reload.visibility ).not_to eql( Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC )
          end
        end

        context "changing to authenticated" do
          it "should be allowed" do
            expect {
              post :update, id: file.id, visibility: Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_AUTHENTICATED
            }.not_to raise_error
            expect( file.reload.visibility ).to eql( Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_AUTHENTICATED )
            expect( file.reload.request_for_visibility_change ).to be_nil
          end
        end

        context "changing to public pending" do
          before { post :update, id: file.id, visibility: 'open-pending' }
          it "should set authenticated visibility" do
            expect(file.reload.visibility).to eql(Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_AUTHENTICATED)
          end
          it "should set request for change" do
            expect( file.reload.request_for_visibility_change ).to eql(Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC)
          end
        end

      end

      describe "public file" do
        let!(:file) { public_file }

        context "changing to authenticated" do
          it "should not be allowed" do
            expect {
              post :update, id: file.id, visibility: Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_AUTHENTICATED
            }.to raise_error("Changing of visibility to #{Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_AUTHENTICATED} forbidden")
            expect( file.reload.visibility ).to eql( Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC )
            expect( file.reload.request_for_visibility_change ).to be_nil
          end
        end

        context "changing to public pending" do
          it "should not be allowed" do
            expect {
              post :update, id: file.id, visibility: 'open-pending'
            }.to raise_error("Changing of visibility to open-pending forbidden")
            expect( file.reload.visibility ).to eql( Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC )
            expect( file.reload.request_for_visibility_change ).to be_nil
          end
        end

      end
    end

    describe "visibility_request_notifications" do
      before {
        @old_visibility_recipients=DURHAM_CONFIG['visibility_notification_users']
        DURHAM_CONFIG['visibility_notification_users']=[other_user.user_key]
      }
      after { DURHAM_CONFIG['visibility_notification_users']=@old_visibility_recipients }

      context "requesting change" do
        let!(:file) { private_file }
        before { post :update, id: file.id, visibility: 'open-pending' }

        it "should send a notification" do
          expect(other_user.reload.mailbox.inbox.to_a).not_to be_empty
        end
      end

      context "admin modifying" do
        let!(:file) { other_private_file }
        before {
          sign_in other_user
          post :update, id: file.id, visibility: 'open-pending'
        }
        it "should not send a notification" do
          expect(other_user.reload.mailbox.inbox.to_a).to be_empty
        end
      end

    end

  end
end
