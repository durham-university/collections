require 'rails_helper'

RSpec.describe DownloadsController, type: :controller do

  describe "#file_name" do
    let( :asset_title ) { ['Test Asset'] }
    let( :asset_id ) { 'w9505044z' }
    let( :filename ) { ['test.pdf'] }
    let( :version_label ) { 'version1' }
    let( :params_file ) { 'content' }
    let!( :asset ) {
      double('asset').tap do |asset|
        allow(asset).to receive(:filename).and_return(filename)
        allow(asset).to receive(:title).and_return(asset_title)
        allow(asset).to receive(:id).and_return(asset_id)
        allow(asset).to receive(:content).and_return(
          OpenStruct.new( latest_version: OpenStruct.new( label: version_label ) )
        )
        allow(controller).to receive(:asset).and_return(asset)
      end
    }
    
    let(:params){ {file: params_file} }

    before {
      allow(controller).to receive(:params).and_return( params.with_indifferent_access )
    }

    subject { controller.file_name }

    it "combines all pieces" do
      expect(subject).to eql "test-#{asset_id}-#{version_label}.pdf"
    end
    
    context "with filename that has no extension" do
      let( :filename ) { ['just_test'] }
      it "combines all pieces but extension" do
        expect(subject).to eql "just_test-#{asset_id}-#{version_label}"
      end
    end

    context "when getting a derivative" do
      let( :params_file ) { 'thumbnail' }
      it "it adds type but doesn't add file type" do
        expect(subject).to eql "test-#{asset_id}-#{version_label}-thumbnail"
      end
    end
    
    context "when specifying filename in params" do
      let( :params_file ) { 'thumbnail' }
      let(:params){ {file: params_file, filename: 'moo.pdf'} }
      it "it uses the filename" do
        expect(subject).to eql "moo.pdf"
      end
    end

  end

end
