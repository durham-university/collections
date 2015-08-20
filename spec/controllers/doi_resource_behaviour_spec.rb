require 'rails_helper'

RSpec.describe "doi_resource_behaviour" do
  let(:user) { FactoryGirl.find_or_create(:registered_user_1) }
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
  let(:collection_attributes){
    file_attributes.tap do |file_attributes|
      file_attributes[:title]=file_attributes[:title].first
      file_attributes.delete :rights
      file_attributes[:resource_type]=['Collection']
    end
  }

  let(:file_contributors) {
    [
      FactoryGirl.build(:contributor, contributor_name: ['Contributor 1'],
                                      affiliation: ['Affiliation 1'],
                                      role: ['http://id.loc.gov/vocabulary/relators/cre']),
      FactoryGirl.build(:contributor, contributor_name: ['Contributor 2'],
                                      affiliation: ['Affiliation 2'],
                                      role: ['http://id.loc.gov/vocabulary/relators/cre']),
      FactoryGirl.build(:contributor, contributor_name: ['Contributor 3'],
                                      affiliation: ['Affiliation 3'],
                                      role: ['http://id.loc.gov/vocabulary/relators/edt'])
    ]
  }
  let(:managed_file) {
    file=FactoryGirl.create(:public_file, depositor: user)
    file.attributes = file_attributes
    file.contributors = file_contributors
    file.identifier += [file.full_mock_doi]
    file.doi_published = DateTime.now
    file.datacite_document = file.doi_metadata.to_json
    file.skip_update_datacite = true
    file.save
    file
  }
  let(:unmanaged_file) {
    file=FactoryGirl.create(:public_file, depositor: user)
    file.attributes = file_attributes
    file.contributors = file_contributors
    file.save
    file
  }
  let(:managed_collection){
    collection=FactoryGirl.create(:collection, depositor: user)
    collection.attributes = collection_attributes
    collection.contributors = file_contributors
    collection.identifier += [collection.full_mock_doi]
    collection.doi_published = DateTime.now
    collection.datacite_document = collection.doi_metadata.to_json
    collection.skip_update_datacite = true
    collection.save
    collection
  }
  let(:unmanaged_collection){
    collection=FactoryGirl.create(:collection, depositor: user)
    collection.attributes = collection_attributes
    collection.contributors = file_contributors
    collection.save
    collection
  }

  describe "restrict_local_doi_changes" do
    describe GenericFilesController do
      routes { Sufia::Engine.routes }
      context "managed file" do
        let!(:file) { managed_file }
        it "should not allow local doi to be removed" do
          expect {
            post :update, id: file.id, generic_file: { identifier: ['arXiv:0123.0000', 'http://something.else.com'] }
          }.to raise_error("Local DOI cannot be removed")
          expect(file.reload.identifier).to include file.full_mock_doi
        end
      end

      context "unmanaged file" do
        let!(:file) { unmanaged_file }
        it "should not allow local doi to be added" do
          expect {
            post :update, id: file.id, generic_file: { identifier: [file.full_mock_doi, 'arXiv:0123.0000', 'http://something.else.com'] }
          }.to raise_error("Local DOI cannot be added")
          expect(file.reload.identifier).not_to include file.full_mock_doi
        end
      end
    end

    describe CollectionsController do
      routes { Hydra::Collections::Engine.routes }
      context "managed collection" do
        let!(:collection) { managed_collection }
        it "should not allow local doi to be removed" do
          expect {
            post :update, id: collection.id, collection: { identifier: ['arXiv:0123.0000', 'http://something.else.com'] }
          }.to raise_error("Local DOI cannot be removed")
          expect(collection.reload.identifier).to include collection.full_mock_doi
        end
      end

      context "unmanaged collection" do
        let!(:collection) { unmanaged_collection }
        it "should not allow local doi to be added" do
          expect {
            post :update, id: collection.id, collection: { identifier: [collection.full_mock_doi, 'arXiv:0123.0000', 'http://something.else.com'] }
          }.to raise_error("Local DOI cannot be added")
          expect(collection.reload.identifier).not_to include collection.full_mock_doi
        end
      end
    end
  end
end
