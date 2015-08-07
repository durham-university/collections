require 'rails_helper'

RSpec.describe "doi/show.html.erb", type: :view do
  let(:file) { FactoryGirl.create(:public_file, :test_data) }

  before {
    view.class.send :define_method, :blacklight_config, lambda { Blacklight::Configuration.new }
    assign(:resource, file)
    assign(:id, file.id)
    assign(:metadata_errors, file.validate_doi_metadata)
    assign(:presenter, Sufia::GenericFilePresenter.new(file) )
    assign(:model_class, "generic_file")
    controller.request.path_parameters[:id] = file.id
  }

  let(:page) { Capybara::Node::Simple.new(rendered) }

  context "doi can be published" do
    before { render }
    it "should have publish button" do
      expect(page).to have_selector('input#publish-doi-submit')
    end

    it "should have the title" do
      expect(page).to have_xpath("//dd[contains(., '#{file.title.first}')]")
    end

    it "should have the creator" do
      creators = (file.contributors.to_a.select do |c| c.role.first == 'http://id.loc.gov/vocabulary/relators/cre' end)
      creators.each do |c|
        expect(page).to have_xpath("//dd[contains(., '#{Sufia.config.contributor_roles_reverse[c.role.first]}')]")
        expect(page).to have_xpath("//dd[contains(., '#{c.to_s}')]")
      end
    end

    it "should have the doi visible" do
      expect(rendered).to include(file.full_mock_doi)
    end

    it "should not have any error messages" do
      all_errors = GenericFile.new.validate_doi_metadata
      all_errors.each do |e|
        expect(rendered).not_to include(e)
      end
    end

    it "should have an edit link" do
      expect(page).to have_selector('a', text: 'Edit file')
    end
    it "should have a back link" do
      expect(page).to have_selector('a', text: 'Back')
    end
  end

  context "file not public" do
    let(:file) { FactoryGirl.create(:registered_file, :test_data) }
    before { render }

    it "should not have publish button" do
      expect(page).not_to have_selector('input#publish-doi-submit')
    end

    it "should have an error message" do
      expect(rendered).to include('The resource must be Open Access')
    end

    it "should have the doi visible" do
      expect(rendered).to include(file.full_mock_doi)
    end

    it "should have an edit link" do
      expect(page).to have_selector('a', text: 'Edit file')
    end
    it "should have a back link" do
      expect(page).to have_selector('a', text: 'Back')
    end
  end

  context "file missing creator" do
    let(:file) {
      FactoryGirl.create(:public_file, :test_data) do |f|
        f.contributors=(f.contributors.to_a.select do |c|
          c.role.first != 'http://id.loc.gov/vocabulary/relators/cre'
        end)
      end

    }
    before { render }
    it "should not have publish button" do
      expect(page).not_to have_selector('input#publish-doi-submit')
    end
    it "should have an error message" do
      expect(rendered).to include('The resource must have a creator')
    end

  end

  context "file missing resource type" do
    let(:file) {
      FactoryGirl.create(:public_file, :test_data) do |f|
        f.resource_type = []
      end
    }
    before { render }
    it "should not have publish button" do
      expect(page).not_to have_selector('input#publish-doi-submit')
    end
    it "should have an error message" do
      expect(rendered).to include('The resource must have a resource type')
    end
  end

  context "file missing title" do
    let(:file) {
      FactoryGirl.create(:public_file, :test_data) do |f|
        f.title=[]
      end
    }
    before { render }
    it "should not have publish button" do
      expect(page).not_to have_selector('input#publish-doi-submit')
    end
    it "should have an error message" do
      expect(rendered).to include('The resource must have a title')
    end
  end

  context "file already has a local doi" do
    let(:file) { f=FactoryGirl.create(:public_file, :test_data, :public_doi) }
    before { render }
    it "should not have publish button" do
      expect(page).not_to have_selector('input#publish-doi-submit')
    end
    it "should have an error message" do
      expect(rendered).to include('This resource already has a local DOI')
    end
  end
  context "file already has an outside doi" do
    let(:file) {
      FactoryGirl.create(:public_file, :test_data) do |f|
        f.identifier << 'doi:1234/1234'
      end
    }
    before { render }
    it "should have publish button" do
      expect(page).to have_selector('input#publish-doi-submit')
    end
    it "should not have an error message" do
      expect(rendered).not_to include('This resource already has a local DOI')
    end
    it "should report the existing doi" do
      expect(rendered).to include('doi:1234/1234')
    end
  end

end
