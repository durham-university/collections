require 'rails_helper'

RSpec.describe Contributor do
  let(:file) { FactoryGirl.create(:generic_file) }
  before {
    file.contributors.new( contributor_name: ['Test Contributor'], affiliation: ['Test Affiliation'], role: ['http://id.loc.gov/vocabulary/relators/cre'])
  }
  let(:contributor) { file.contributors.first }
  subject { contributor }

  it "should have a name" do
    expect(subject.contributor_name).to eql(['Test Contributor'])
  end
  it "should have an affiliation" do
    expect(subject.affiliation).to eql(['Test Affiliation'])
  end
  it "should have a role" do
    expect(subject.role).to eql(['http://id.loc.gov/vocabulary/relators/cre'])
  end

  describe "to_s" do
    subject { contributor.to_s }
    it "should include the name" do
      expect(subject.index(contributor.contributor_name.first)).to be_truthy
    end
    it "should include the affiliation" do
      expect(subject.index(contributor.affiliation.first)).to be_truthy
    end
    it "should not include the role" do
      expect(subject.index('http://id.loc.gov/vocabulary/relators/cre')).to be_falsy
      expect(subject.index('creator')).to be_falsy
      expect(subject.index('Creator')).to be_falsy
    end
  end
end
