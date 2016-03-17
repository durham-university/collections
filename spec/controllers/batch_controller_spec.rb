require 'rails_helper'

RSpec.describe BatchController, type: :controller do
  routes { Sufia::Engine.routes }
  let(:user) { FactoryGirl.find_or_create(:user) }
  before { sign_in user }
  
  describe "update" do
    let(:batchid) { '123' } #can be anything really
    it "does contributor processing" do
      expect(Sufia.queue).to receive(:push) do |job|
        expect(job).to be_a(BatchUpdateJob)
        expect(job.file_attributes[:contributors_attributes].first[:affiliation].count).to eql(2)
        expect(job.file_attributes[:contributors_attributes].first[:role].count).to eql(2)
      end
      post :update, id: batchid, generic_file: { title: ['New test collection'], contributors_attributes: [{contributor_name:['Name'], affiliation:['Af1 ; Af2'], role:['','role1','role2']}] }
    end
  end
end
