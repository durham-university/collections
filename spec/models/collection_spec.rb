require 'rails_helper'
require 'shared/ark_resource'

RSpec.describe Collection do
  let(:collection) { FactoryGirl.create(:collection,:test_data) }
  let(:collection_fedora) { Collection.find(collection.id) }
  let(:collection_solr) { Collection.load_instance_from_solr(collection.id) }

  it_behaves_like "ark resource" do
    let(:resource_factory) { :collection }
  end

  it "should have multi-value description" do
    collection.description = ['description1', 'description2']
    collection.save
    collection.reload
    expect(collection.description).to eql(['description1', 'description2'])
  end

  it "should not have rights field" do
    expect(collection).not_to respond_to(:rights)
  end

#  it "should have doi functionality" do
#    expect(subject).to respond_to :doi
#  end
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

    let(:attribute_keys) {
      ['title','description','subject','resource_type','identifier','tag','related_url','funder','abstract','research_methods','date_uploaded']
    }
    let(:expected_values) {
      multi_value_sort({"title"=>"Test title", "description"=>["Description"], "subject"=>["subject1", "subject2"], "resource_type"=>["Collection"], "identifier"=>["http://something.else.com", "arxiv:0123.0000", "isbn:123456"] + [collection.local_ark], "tag"=>["keyword1", "keyword2"], "related_url"=>["http://related.url.com/test"], "funder"=>["Funder 1"], "abstract"=>["Test abstract"], "research_methods"=>["Test research method 1", "Test research method 2"], "date_uploaded"=>DateTime.parse("2015-07-16T12:44:38.000+01:00").to_s})
    }

    describe "loading from Fedora" do
      subject { collection_fedora }
      it "should have all the right values" do
        attrs = multi_value_sort subject.attributes.slice(*attribute_keys)
        # Fedora returns dates as Date objects, convert to string for easier comparison
        attrs['date_uploaded'] = attrs['date_uploaded'].to_s
        expect( attrs ).to eql( expected_values )
      end
      it "should have the contributors" do
        expect( subject.contributors.map &:to_hash ).to eql([
          {contributor_name: ['Contributor 1'], affiliation: ['Affiliation 1','Affiliation 1/2'], role: ['http://id.loc.gov/vocabulary/relators/cre']},
          {contributor_name: ['Contributor 2'], affiliation: ['Affiliation 2'], role: ['http://id.loc.gov/vocabulary/relators/cre']},
          {contributor_name: ['Contributor 3'], affiliation: ['Affiliation 3'], role: ['http://id.loc.gov/vocabulary/relators/edt']}
        ])
      end
    end
    describe "loading from Solr" do
      subject { collection_solr }
      it "should have all the right values" do
        attrs = multi_value_sort subject.attributes.slice(*attribute_keys)
        attrs['date_uploaded'] = attrs['date_uploaded'].to_s
        expect( attrs ).to eql( expected_values )
      end
      it "should have the contributors" do
        expect( subject.contributors.map &:to_hash ).to eql([
          {contributor_name: ['Contributor 1'], affiliation: ['Affiliation 1','Affiliation 1/2'], role: ['http://id.loc.gov/vocabulary/relators/cre']},
          {contributor_name: ['Contributor 2'], affiliation: ['Affiliation 2'], role: ['http://id.loc.gov/vocabulary/relators/cre']},
          {contributor_name: ['Contributor 3'], affiliation: ['Affiliation 3'], role: ['http://id.loc.gov/vocabulary/relators/edt']}
        ])
      end
    end
  end

  describe "deletion" do
    it "should be possible to delete the collection" do
      collection.reload
      #expect(collection).to receive(:queue_doi_metadata_update).with(collection.depositor,hash_including(destroyed: true))
      expect { collection.destroy }.not_to raise_error
      expect(Collection.where(id: collection.id).to_a).to be_empty
    end
  end
end
