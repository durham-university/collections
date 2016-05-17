require 'rails_helper'
require 'shared/ark_resource'

RSpec.describe GenericFile do

  let(:file) { FactoryGirl.create(:generic_file) }
  let(:file_saved) {
    file.save if file.changed_for_autosave?
    file
  }
  let(:file_fedora) { GenericFile.find(file_saved.id) }
  let(:file_solr) { GenericFile.load_instance_from_solr(file_saved.id) }

  subject { file }

  it_behaves_like "ark resource" do
    let(:resource_factory) { :generic_file }
  end

  it "should have doi functionality" do
    expect(subject).to respond_to :doi
  end
  it "should have contributors" do
    expect(subject).to respond_to :contributors
  end
  it "should not have contributor" do
    expect(subject).not_to respond_to :contributor
  end
  it "should have local metadata additions" do
    expect(subject).to respond_to :funder
    expect(subject).to respond_to :abstract
    expect(subject).to respond_to :research_methods
  end
  it "should have Sufia metadata" do
    expect(subject).to respond_to :title
    expect(subject).to respond_to :description
    expect(subject).to respond_to :depositor
    expect(subject).to respond_to :resource_type
    expect(subject).to respond_to :tag
    expect(subject).to respond_to :rights
    expect(subject).to respond_to :date_created
    expect(subject).to respond_to :date_uploaded
    expect(subject).to respond_to :date_modified
    expect(subject).to respond_to :subject
    expect(subject).to respond_to :language
    expect(subject).to respond_to :identifier
    expect(subject).to respond_to :based_near
    expect(subject).to respond_to :related_url
  end

  describe "setting the title" do
    before { file.title = ["My Favorite Things"] }
    subject { file.title }
    it { is_expected.to eql ["My Favorite Things"] }
  end

  describe "persisting" do
    let(:file_attributes) {
      {
        'title' => ['Test title'],
        'description' => ['Test description'],
        'resource_type' => ['Image'],
        'tag' => [ 'keyword1', 'keyword2' ],
        'rights' => [ 'http://creativecommons.org/publicdomain/zero/1.0/' ],
        'subject' => [ 'subject1', 'subject2' ],
        'language' => [ 'English', 'Finnish' ],
        'identifier' => [ 'http://www.example.com/identifier1', '1234/1231' ],
        'based_near' => [ 'Durham' ],
        'related_url' => [ 'http://www.example.com/related' ]
      }
    }
    let(:file_contributors) {
      [
        FactoryGirl.build(:contributor, contributor_name: ['Contributor 1'],
                                        affiliation: ['Affiliation 1'],
                                        role: ['http://id.loc.gov/vocabulary/relators/cre'],
                                        order: ['1']),
        FactoryGirl.build(:contributor, contributor_name: ['Contributor 2'],
                                        affiliation: ['Affiliation 2'],
                                        role: ['http://id.loc.gov/vocabulary/relators/cre'],
                                        order: ['2']),
        FactoryGirl.build(:contributor, contributor_name: ['Contributor 3'],
                                        affiliation: ['Affiliation 3'],
                                        role: ['http://id.loc.gov/vocabulary/relators/edt'],
                                        order: ['3'])
      ]
    }

    before {
      file.attributes = file_attributes
      file.contributors = file_contributors
    }
    describe "loading from Fedora" do
      subject { file_fedora }
      it "should have all the right values" do
        expect( subject.attributes.slice(*(file_attributes.keys.map &:to_s)) ).to eql(file_attributes)
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
      subject { file_solr }
      it "should have all the right values" do
        expect( subject.attributes.slice(*(file_attributes.keys.map &:to_s)) ).to eql(file_attributes)
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
