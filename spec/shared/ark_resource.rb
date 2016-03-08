RSpec.shared_examples "ark resource" do
  let(:resource_factor) { raise 'Must set resource_factory parameter' }
  let(:resource) { FactoryGirl.build(resource_factory) }

  describe "#assign_id" do
    it "calls #id_from_ark" do
      expect(resource).to receive(:id_from_ark).and_return('abcdefgh')
      expect(resource.assign_id).to eql('abcdefgh')
    end
  end

  context "with no naan set" do
    before { allow(resource.class).to receive(:ark_naan).and_return(nil) }
    describe "#assign_new_ark" do
      before { resource.identifier = [] }
      it "doesn't do anything" do
        resource.assign_new_ark
        expect(resource.identifier).to be_empty
      end
    end
    describe "#id_from_ark" do
      before { resource.instance_variable_set(:@minted_ark_id,'ark:/12345/abcdefgh') }
      it "doesn't do anything" do
        expect(resource.id_from_ark).to be_nil
      end
    end
  end

  context "with naan set" do
    let(:ark_naan) { '12345' }
    let(:id) { 'abcdefgh' }
    before {
      allow(resource.class).to receive(:ark_naan).and_return(ark_naan)
      allow(resource).to receive(:service).and_return(
        double('id mint service', mint: id)
      )
    }
    describe "#assign_new_ark" do
      before { resource.identifier = ['doi:other'] }
      it "assigns a new identifier" do
        resource.assign_new_ark
        expect(resource.identifier).to match_array(['doi:other',"ark:/#{ark_naan}/#{id}"])
      end
      it "sets the new identifier in instance variable" do
        resource.assign_new_ark
        expect(resource.instance_variable_get(:@minted_ark_id)).not_to be_nil
      end
      it "doesn't assign a new identifier if local ark already exists" do
        resource.identifier += ["ark:/#{ark_naan}/dummyark"]
        resource.assign_new_ark
        expect(resource.identifier).to match_array(['doi:other',"ark:/#{ark_naan}/dummyark"])
        expect(resource.instance_variable_get(:@minted_ark_id)).to be_nil
      end
    end
    describe "#id_from_ark" do
      it "does not use #local_ark but instead use instance variable" do
        resource.instance_variable_set(:@minted_ark_id,"ark:/#{ark_naan}/#{id}")
        expect(resource).not_to receive(:local_ark)
        expect(resource.id_from_ark).to eql(id)
      end
      it "returns nil if instance variable is not set" do
        allow(resource).to receive(:local_ark).and_return(['doi:other',"ark:/#{ark_naan}/dummyark"])
        expect(resource.id_from_ark).to be_nil
      end
    end
    describe "#local_ark" do
      it "finds the identifier" do
        resource.identifier = ["ark:/#{ark_naan}/#{id}"]
        expect(resource.local_ark).to eql("ark:/#{ark_naan}/#{id}")
      end
      it "sorts identifiers" do
        resource.identifier = ["ark:/#{ark_naan}/bcd","ark:/#{ark_naan}/aaa"]
        expect(resource.local_ark).to eql("ark:/#{ark_naan}/aaa")
      end
      it "only considers identifiers with correct naan" do
        resource.identifier = ["ark:/01010/#{id}"]
        expect(resource.local_ark).to be_nil
      end
    end
  end
end
