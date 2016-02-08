require 'rails_helper'

RSpec.shared_examples "doi_resource_behaviour" do
  let(:managed_resource) {
    FactoryGirl.create(resource_factory, :test_data, :public_doi, title: ['Test title'], depositor: user)
  }
  let(:unmanaged_resource) { FactoryGirl.create(resource_factory, :test_data, title: ['Test title'], depositor: user) }
  let(:resource_params) { nil }

  let(:params) {
    { id: resource.id }.tap do |params|
      params[ resource.class.to_s.underscore.to_sym ] = resource_params if resource_params
    end
  }

  describe "restrict_published_doi_deletion" do
    context "managed resource" do
      let!(:resource) { managed_resource }
      it "should not be allowed to be deleted" do
        expect {
          post :destroy, params
        }.to raise_error("Cannot delete resource with a published local DOI")
        expect(resource.class.find(resource.id)).to be_present
      end
    end
  end

  describe "restrict_local_doi_changes" do
    context "managed resource" do
      let!(:resource) { managed_resource }
      let(:resource_params) { { identifier: ['arXiv:0123.0000', 'http://something.else.com'] } }
      it "should not allow local doi to be removed" do
        expect {
          post :update, params
        }.to raise_error("Local DOI cannot be removed")
        expect(resource.reload.identifier).to include resource.full_mock_doi
      end
      context "with admin user" do
        let(:user) { FactoryGirl.find_or_create(:admin_user) }
        before { allow(Sufia.queue).to receive(:push) }
        it "should allow local doi to be removed" do
          post :update, params
          expect(resource.reload.identifier).not_to include resource.full_mock_doi
        end
      end
    end

    context "unmanaged file" do
      let!(:resource) { unmanaged_resource }
      let(:resource_params) { { identifier: [resource.full_mock_doi, 'arXiv:0123.0000', 'http://something.else.com'] } }
      it "should not allow local doi to be added" do
        expect {
          post :update, params
        }.to raise_error("Local DOI cannot be added")
        expect(resource.reload.identifier).not_to include resource.full_mock_doi
      end
      context "with admin user" do
        let(:user) { FactoryGirl.find_or_create(:admin_user) }
        before { allow(Sufia.queue).to receive(:push) }
        it "should allow local doi to be added" do
          post :update, params
          expect(resource.reload.identifier).to include resource.full_mock_doi
        end
      end
    end
  end

  describe "metadata changes with a published doi" do
    let(:resource_params) { { title: ['Changed title'] } }
    let!(:resource) { managed_resource }
    it "should not allow metadata changes" do
      post :update, params
      expect(resource.reload.title).to eql(['Test title'])
    end

    context "with admin user" do
      let(:user) { FactoryGirl.find_or_create(:admin_user) }
      before { allow(Sufia.queue).to receive(:push) }
      it "should allow metadata changes" do
        post :update, params
        expect(resource.reload.title).to eql(['Changed title'])
      end
    end
  end
end
