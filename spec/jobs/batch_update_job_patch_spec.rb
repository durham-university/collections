require 'rails_helper'
require 'shared/batch_visibility_editor'

RSpec.describe BatchUpdateJob do

  it_behaves_like "a batch visibility editor" do
    let(:batch) { Batch.create }
    let!(:private_file) { FactoryGirl.create(:generic_file, :test_data, depositor: user, batch: batch) }
    let!(:registered_file) { FactoryGirl.create(:registered_file, :test_data, depositor: user, batch: batch) }
    let!(:pending_file) {
      FactoryGirl.create(:registered_file, :test_data, depositor: user, batch: batch,
        request_for_visibility_change: Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC
      )
    }
    let!(:public_file) { FactoryGirl.create(:public_file, :test_data, depositor: user, batch: batch) }
    let!(:other_file) { FactoryGirl.create(:registered_file, :test_data, depositor: other_user, batch: batch) }
    let(:user) { FactoryGirl.create(:user) }
    let(:other_user) { FactoryGirl.create(:user) }

    let(:job) { BatchUpdateJob.new(user.user_key, batch.id, {}, {}, visibility) }

    before {
      @old_visibility_recipients=DURHAM_CONFIG['visibility_notification_users']
      DURHAM_CONFIG['visibility_notification_users']=[other_user.user_key]
    }
    after { DURHAM_CONFIG['visibility_notification_users']=@old_visibility_recipients }

    before {
      allow(Sufia.queue).to receive(:push)
      job.run
      [private_file, registered_file, pending_file, public_file, other_file] \
        .each &:reload
    }
  end

end
