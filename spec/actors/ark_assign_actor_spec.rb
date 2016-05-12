require 'rails_helper'

RSpec::Matchers.define_negated_matcher :not_change, :change

RSpec.describe ArkAssignActor do
  
  before {
    allow(GenericFile).to receive(:ark_naan).and_return('12345')
    allow(Collection).to receive(:ark_naan).and_return('12345')
  }
  
  let!(:generic_file_with_ark) { 
    FactoryGirl.create(:generic_file, :test_data).tap do |gf| expect(gf.local_ark).to be_present end
  }
  let!(:collection_with_ark) { 
    FactoryGirl.create(:generic_file, :test_data).tap do |c| expect(c.local_ark).to be_present end
  }
  let!(:generic_file_no_ark) {
    FactoryGirl.create(:generic_file, :test_data).tap do |gf|
      gf.identifier -= [gf.local_ark]
      gf.save
      expect(gf.local_ark).to be_nil
    end
  }
  let!(:collection_no_ark) {
    FactoryGirl.create(:collection, :test_data).tap do |c|
      c.identifier -= [c.local_ark]
      c.save
      expect(c.local_ark).to be_nil
    end
  }
  
  let(:actor) { ArkAssignActor.new }

  describe "#assign_missing_arks" do
    it "assigns arks to ones that don't have it and no others" do
      expect {
        actor.assign_missing_arks
        generic_file_with_ark.reload
        collection_with_ark.reload
        generic_file_no_ark.reload
        collection_no_ark.reload
      } 
      .to \
      not_change { generic_file_with_ark.identifier.sort } .and \
      not_change { collection_with_ark.identifier.sort } .and \
      not_change { generic_file_with_ark.title.to_a } .and \
      not_change { generic_file_no_ark.title.to_a } .and \
      not_change { collection_with_ark.title.to_s } .and \
      not_change { collection_no_ark.title.to_s }
      
      expect(generic_file_no_ark.reload.local_ark).to eql("ark:/#{GenericFile.ark_naan}/#{generic_file_no_ark.id}")
      expect(collection_no_ark.reload.local_ark).to eql("ark:/#{Collection.ark_naan}/#{collection_no_ark.id}")
    end
  end

end