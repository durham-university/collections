require 'rails_helper'

RSpec.describe UpdateDataciteJob do
  let(:file) { FactoryGirl.create(:public_file, :test_data, depositor: user) }
  let(:user) { FactoryGirl.create(:user) }
  let(:job) { UpdateDataciteJob.new(file.id,user) }

  describe "marshalling" do
    # Resque serialises objects using Marshal.dump so make sure it works.
    it "should be Marshallable" do
      expect { Marshal.dump(job) }.not_to raise_error
    end
  end

  describe "send_message" do
    let(:message) { user.reload.mailbox.inbox.last.messages.first }
    it "user should receive the message" do
      expect { job.send_message('test title','test message') }.to change \
        { user.reload.mailbox.inbox.count }.by(1)
      expect(message.body).to eql('test message')
      expect(message.subject).to eql('test title')
    end
  end

  describe "do_update" do
    before {
      @time = DateTime.now
      expect(file).not_to receive(:update_datacite_metadata)
    }

    context "when not minting" do
      before {
        expect_any_instance_of(Datacite).to receive(:metadata)
        expect_any_instance_of(Datacite).not_to receive(:mint)
        job.do_update
        file.reload
      }

      it "should set the metadata fields" do
        expect(file.identifier).to include(file.full_mock_doi)
        expect(file.doi_published).to be >= @time
        expect(JSON.parse(file.datacite_document)).to eql(file.doi_metadata.with_indifferent_access)
      end

      it "should unset do_metadata" do
        expect(job.do_metadata).to eql(false)
      end
    end

    context "when minting" do
      let(:job) { UpdateDataciteJob.new(file.id,user, do_mint: true) }
      before {
        expect_any_instance_of(Datacite).to receive(:metadata)
        expect_any_instance_of(Datacite).to receive(:mint).with(file.doi_landing_page,file.mock_doi)
        job.do_update
        file.reload
      }

      it "should set the metadata fields" do
        expect(file.identifier).to include(file.full_mock_doi)
        expect(file.doi_published).to be >= @time
        expect(JSON.parse(file.datacite_document)).to eql(file.doi_metadata.with_indifferent_access)
      end

      it "should unset do_metadata" do
        expect(job.do_metadata).to eql(false)
      end
    end
  end

  describe "run" do
    context "when everything works" do
      it "should do_update and send_message" do
        expect(job).to receive(:do_update)
        expect(job).to receive(:send_message)
        expect(Sufia.queue).not_to receive(:push)
        job.run
      end
    end
    context "when unknown error is raised" do
      it "should send error notification and raise error" do
        expect(job).to receive(:do_update) { raise "mock error" }
        expect(job).to receive(:send_failed_message)
        expect(Sufia.queue).not_to receive(:push)
        expect { job.run }.to raise_error
      end
    end
    context "when network error is raised" do
      it "should send error notification and reque the job" do
        expect(job).to receive(:do_update) { raise Datacite::DataciteUpdateException.new('message','body',501) }
        expect(job).to receive(:send_retry_message)
        expect(Sufia.queue).to receive(:push).with(UpdateDataciteJob)
        job.run
      end
    end
  end

end
