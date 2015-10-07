require 'rails_helper'
require 'shared/batch_visibility_editor'
require 'shared/nested_contributors_behaviour'

RSpec.describe BatchEditsController, type: :controller do

  it_behaves_like "a batch visibility editor" do
    let(:batch) { [private_file.id, registered_file.id, pending_file.id, public_file.id, other_file.id] }
    let(:private_file) { FactoryGirl.create(:generic_file, :test_data, depositor: user) }
    let(:registered_file) { FactoryGirl.create(:registered_file, :test_data, depositor: user) }
    let(:pending_file) {
      FactoryGirl.create(:registered_file, :test_data, depositor: user,
        request_for_visibility_change: Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC
      )
    }
    let(:public_file) { FactoryGirl.create(:public_file, :test_data, depositor: user) }
    let(:other_file) { FactoryGirl.create(:registered_file, :test_data, depositor: other_user) }
    let(:user) { FactoryGirl.create(:user) }
    let(:other_user) { FactoryGirl.create(:user) }

    before {
      @old_visibility_recipients=DURHAM_CONFIG['visibility_notification_users']
      DURHAM_CONFIG['visibility_notification_users']=[other_user.user_key]
    }
    after { DURHAM_CONFIG['visibility_notification_users']=@old_visibility_recipients }

    before {
      sign_in user
      request.env["HTTP_REFERER"] = "/"
      put :update, update_type: 'update', batch_document_ids: batch, visibility: visibility
      [private_file, registered_file, pending_file, public_file, other_file] \
        .each &:reload
    }
  end

  it_behaves_like "nested_contributors_behaviour" do
    let(:user) { FactoryGirl.create(:user) }
    let(:resource) { FactoryGirl.create(:generic_file,:test_data,depositor: user) }
    let(:params) { { update_type: 'update', batch_document_ids: [resource.id]} }
    before { sign_in user }
  end

end
