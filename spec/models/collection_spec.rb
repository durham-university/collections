require 'rails_helper'

RSpec.describe Collection do
  let(:collection) { FactoryGirl.create(:collection) }
  let(:collection_saved) {
    collection.save if collection.changed_for_autosave?
    collection
  }
  let(:collection_fedora) { Collection.find(collection_saved.id) }
  let(:collection_solr) { Collection.load_instance_from_solr(collection_saved.id) }

  it "should have multi-value description" do
    collection.description = ['description1', 'description2']
    collection.save
    collection.reload
    expect(collection.description).to eql(['description1', 'description2'])
  end

  it "should not have rights field" do
    expect(collection).not_to respond_to(:rights)
  end

  it "should have doi functionality" do
    expect(subject).to respond_to :doi
  end
  it "should have contributors" do
    expect(subject).to respond_to :contributors
  end
  it "should have local metadata additions" do
    expect(subject).to respond_to :funder
    expect(subject).to respond_to :abstract
    expect(subject).to respond_to :research_methods
  end
  it "should have Hydra-Collections metadata" do
    expect(subject).to respond_to :title
    expect(subject).to respond_to :description
    expect(subject).to respond_to :depositor
    expect(subject).to respond_to :resource_type
    expect(subject).to respond_to :tag
    expect(subject).to respond_to :date_created
    expect(subject).to respond_to :date_uploaded
    expect(subject).to respond_to :date_modified
    expect(subject).to respond_to :subject
    expect(subject).to respond_to :language
    expect(subject).to respond_to :identifier
    expect(subject).to respond_to :based_near
    expect(subject).to respond_to :related_url
  end

  describe "persisting" do
    let(:collection_attributes) {
      {
        'title' => 'Test title',
        'description' => ['Test description'],
        'resource_type' => ['Collection'],
        'tag' => [ 'keyword1', 'keyword2' ],
        'subject' => [ 'subject1', 'subject2' ],
        'language' => [ 'English', 'Finnish' ],
        'identifier' => [ 'http://www.example.com/identifier1', '1234/1231' ],
        'based_near' => [ 'Durham' ],
        'related_url' => [ 'http://www.example.com/related' ],
      }
    }
    let(:collection_contributors) {
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

    before {
      collection.attributes = collection_attributes
      collection.contributors = collection_contributors
    }
    describe "loading from Fedora" do
      subject { collection_fedora }
      it "should have all the right values" do
        expect( subject.attributes.slice(*(collection_attributes.keys.map &:to_s)) ).to eql(collection_attributes)
      end
      it "should have the contributors" do
        expect( subject.contributors.map &:to_hash ).to eql([
          {contributor_name: ['Contributor 1'], affiliation: ['Affiliation 1'], role: ['http://id.loc.gov/vocabulary/relators/cre']},
          {contributor_name: ['Contributor 2'], affiliation: ['Affiliation 2'], role: ['http://id.loc.gov/vocabulary/relators/cre']},
          {contributor_name: ['Contributor 3'], affiliation: ['Affiliation 3'], role: ['http://id.loc.gov/vocabulary/relators/edt']}
        ])
      end
    end
    describe "loading from Solr" do
      subject { collection_solr }
      it "should have all the right values" do
        expect( subject.attributes.slice(*(collection_attributes.keys.map &:to_s)) ).to eql(collection_attributes)
      end
      it "should have the contributors" do
        expect( subject.contributors.map &:to_hash ).to eql([
          {contributor_name: ['Contributor 1'], affiliation: ['Affiliation 1'], role: ['http://id.loc.gov/vocabulary/relators/cre']},
          {contributor_name: ['Contributor 2'], affiliation: ['Affiliation 2'], role: ['http://id.loc.gov/vocabulary/relators/cre']},
          {contributor_name: ['Contributor 3'], affiliation: ['Affiliation 3'], role: ['http://id.loc.gov/vocabulary/relators/edt']}
        ])
      end
    end
  end
end
