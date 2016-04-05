require 'rails_helper'

RSpec.describe "Atom and RSS feeds", type: :feature do
  let(:user) { FactoryGirl.create(:user) }
  let!(:file1) { FactoryGirl.create(:public_file, :test_data, :public_doi, title: ['First file']) }
  let!(:file2) { FactoryGirl.create(:public_file, :test_data, title: ['Second file']) }
  let!(:file3) { FactoryGirl.create(:public_file, :test_data, :public_doi, title: ['Third file']) }
  let!(:collection) { FactoryGirl.create(:collection, title: 'First collection') }
  
  before { sign_in user }
  
  let(:search_params) { {:"f[doi_published][]" => 'yes', sort: 'doi published', format: feed_format} }
  let(:all_search_params) { {format: feed_format} }
  
  let(:xml) { Nokogiri::XML(page.body) }
  let(:ns) { {'a' => 'http://www.w3.org/2005/Atom'} }
  
  describe "atom feeds" do
    let(:feed_format) { 'atom' }
    it "serves doi atom feeds" do
      visit catalog_index_path(search_params)
      expect(xml.xpath('/a:feed/a:entry/a:title/text()', ns).map(&:to_s)).to eql(['Third file','First file'])
      expect(xml.xpath('/a:feed/a:entry/a:updated', ns).count).to eql(2)
      expect(xml.xpath('/a:feed/a:entry/a:link', ns).count).to eql(2)
      expect(xml.xpath('/a:feed/a:entry/a:id', ns).count).to eql(2)
      expect(xml.xpath('/a:feed/a:entry/a:summary' ,ns).count).to eql(2)
      expect(page).not_to have_content('Second file')
      expect(page).not_to have_content('First collection')
    end
    it "serves all atom feeds" do
      visit catalog_index_path(all_search_params)
      expect(xml.xpath('/a:feed/a:entry/a:title/text()', ns).count).to eql(4)
      expect(xml.xpath('/a:feed/a:entry/a:updated', ns).count).to eql(4)
      expect(xml.xpath('/a:feed/a:entry/a:link', ns).count).to eql(4)
      expect(xml.xpath('/a:feed/a:entry/a:id', ns).count).to eql(4)
      expect(xml.xpath('/a:feed/a:entry/a:summary' ,ns).count).to eql(3) #collection doesn't have a summary
    end
  end

  describe "rss feeds" do
    let(:feed_format) { 'rss' }
    it "serves doi rss feeds" do
      visit catalog_index_path(search_params)
      expect(xml.xpath('/rss/channel/item/title/text()').map(&:to_s)).to eql(['Third file','First file'])
      expect(xml.xpath('/rss/channel/item/pubDate').count).to eql(2)
      expect(xml.xpath('/rss/channel/item/link').count).to eql(2)
      expect(xml.xpath('/rss/channel/item/description').count).to eql(2)
      expect(page).not_to have_content('Second file')
      expect(page).not_to have_content('First collection')
    end
    
    it "serves all rss feeds" do
      visit catalog_index_path(all_search_params)
      expect(xml.xpath('/rss/channel/item/title/text()').count).to eql(4)
      expect(xml.xpath('/rss/channel/item/pubDate').count).to eql(4)
      expect(xml.xpath('/rss/channel/item/link').count).to eql(4)
      expect(xml.xpath('/rss/channel/item/description').count).to eql(3) #collection doesn't have a description
    end
    
  end

end