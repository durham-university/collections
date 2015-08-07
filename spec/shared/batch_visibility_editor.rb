require 'rails_helper'

RSpec.shared_examples "a batch visibility editor" do
  context "setting visibility to public" do
    let(:visibility) { Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC }
    it "should not change visibility of any file and not send notifications" do
      expect(private_file.visibility).to eql(Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE)
      expect(private_file.request_for_visibility_change).to be_nil
      expect(registered_file.visibility).to eql(Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_AUTHENTICATED)
      expect(registered_file.request_for_visibility_change).to be_nil
      expect(pending_file.visibility).to eql(Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_AUTHENTICATED)
      expect(pending_file.request_for_visibility_change).to eql(Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC)
      expect(public_file.visibility).to eql(Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC)
      expect(public_file.request_for_visibility_change).to be_nil
      expect(other_file.visibility).to eql(Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_AUTHENTICATED)
      expect(other_file.request_for_visibility_change).to be_nil
      expect(other_user.reload.mailbox.inbox.to_a).to be_empty
    end
  end

  context "setting visibility to registered" do
    let(:visibility) { Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_AUTHENTICATED }
    it "should only change the private and pending files and not send notifications" do
      expect(private_file.visibility).to eql(Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_AUTHENTICATED)
      expect(private_file.request_for_visibility_change).to be_nil
      expect(registered_file.visibility).to eql(Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_AUTHENTICATED)
      expect(registered_file.request_for_visibility_change).to be_nil
      expect(pending_file.visibility).to eql(Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_AUTHENTICATED)
      expect(pending_file.request_for_visibility_change).to eql(nil)
      expect(public_file.visibility).to eql(Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC)
      expect(public_file.request_for_visibility_change).to be_nil
      expect(other_file.visibility).to eql(Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_AUTHENTICATED)
      expect(other_file.request_for_visibility_change).to be_nil
      expect(other_user.reload.mailbox.inbox.to_a).to be_empty
    end
  end

  context "setting visibility to open-pending" do
    let(:visibility) { 'open-pending' }
    it "should only change the private and registered files and send notifications" do
      expect(private_file.visibility).to eql(Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_AUTHENTICATED)
      expect(private_file.request_for_visibility_change).to eql(Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC)
      expect(registered_file.visibility).to eql(Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_AUTHENTICATED)
      expect(registered_file.request_for_visibility_change).to eql(Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC)
      expect(pending_file.visibility).to eql(Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_AUTHENTICATED)
      expect(pending_file.request_for_visibility_change).to eql(Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC)
      expect(public_file.visibility).to eql(Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC)
      expect(public_file.request_for_visibility_change).to be_nil
      expect(other_file.visibility).to eql(Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_AUTHENTICATED)
      expect(other_file.request_for_visibility_change).to be_nil
      expect(other_user.reload.mailbox.inbox.to_a).not_to be_empty
    end
  end

  context "with admin user" do
    let(:user) { FactoryGirl.create(:admin_user) }
    context "setting visibility to public" do
      let(:visibility) { Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC }
      it "should change all files and not send notifications" do
        expect(private_file.visibility).to eql(Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC)
        expect(private_file.request_for_visibility_change).to be_nil
        expect(registered_file.visibility).to eql(Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC)
        expect(registered_file.request_for_visibility_change).to be_nil
        expect(pending_file.visibility).to eql(Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC)
        expect(pending_file.request_for_visibility_change).to be_nil
        expect(public_file.visibility).to eql(Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC)
        expect(public_file.request_for_visibility_change).to be_nil
        expect(other_file.visibility).to eql(Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC)
        expect(other_file.request_for_visibility_change).to be_nil
        expect(other_user.reload.mailbox.inbox.to_a).to be_empty
      end
    end
    context "setting visibility to restricted" do
      let(:visibility) { Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_AUTHENTICATED }
      it "should change all files and not send notifications" do
        expect(private_file.visibility).to eql(Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_AUTHENTICATED)
        expect(private_file.request_for_visibility_change).to be_nil
        expect(registered_file.visibility).to eql(Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_AUTHENTICATED)
        expect(registered_file.request_for_visibility_change).to be_nil
        expect(pending_file.visibility).to eql(Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_AUTHENTICATED)
        expect(pending_file.request_for_visibility_change).to be_nil
        expect(public_file.visibility).to eql(Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_AUTHENTICATED)
        expect(public_file.request_for_visibility_change).to be_nil
        expect(other_file.visibility).to eql(Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_AUTHENTICATED)
        expect(other_file.request_for_visibility_change).to be_nil
        expect(other_user.reload.mailbox.inbox.to_a).to be_empty
      end
    end
  end
end
