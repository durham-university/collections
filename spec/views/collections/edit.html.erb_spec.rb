require 'rails_helper'

RSpec.describe "collections/edit.html.erb", type: :view do
  let(:collection) { FactoryGirl.create(:collection, :test_data) }
  let(:user) { FactoryGirl.create(:admin_user) }

  before {
    view.class.send :define_method, :blacklight_config, lambda { Blacklight::Configuration.new }
    assign(:collection, collection)
    assign(:id, collection.id)
    assign(:form, Sufia::Forms::CollectionEditForm.new(collection) )
    assign(:model_class, "collection")
    assign(:events, [])
    assign(:response, double('response').tap do |response|
      allow(response).to receive(:total_pages).and_return(1)
      allow(response).to receive(:total).and_return(0)
      allow(response).to receive(:spelling).and_return(double('spelling').tap do |spelling|
        allow(spelling).to receive(:words).and_return([])
      end)
    end)
    controller.request.path_parameters[:id] = collection.id

    sign_in user
  }

  let(:page) { Capybara::Node::Simple.new(rendered) }

  it "renders the page" do
    render
  end
  
  it "has a delete link" do
    render
    expect(page).to have_selector("a[href='#{collection_path(collection)}'][data-method='delete']")
  end
end
