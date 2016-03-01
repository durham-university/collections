require 'rails_helper'

RSpec.describe SchmitDownloadsController, type: :controller do
  
  describe "#download_url" do
    it "uses SCHMIT_CONFIG and routes properly" do
      expect(SCHMIT_CONFIG).to receive(:[]).with('schmit_url').and_return('http://test:3000/schmit/')
      expect(controller).to receive(:params).at_least(:once).and_return({id:'ark:/12345/1234.pdf'})
      expect(controller.send(:download_url)).to eql('http://test:3000/schmit/id/ark:/12345/1234.pdf')
    end    
    
    it "only allows known file suffixes" do
      expect(controller).to receive(:params).at_least(:once).and_return({id:'ark:/12345/1234.json'})
      expect(controller.send(:download_url)).to eql(nil)
    end

    it "requires a file suffix" do
      expect(controller).to receive(:params).at_least(:once).and_return({id:'ark:/12345/1234'})
      expect(controller.send(:download_url)).to eql(nil)
    end
    
    it "only allows ark identifires" do
      expect(controller).to receive(:params).at_least(:once).and_return({id:'1234.pdf'})
      expect(controller.send(:download_url)).to eql(nil)
    end
  end

end