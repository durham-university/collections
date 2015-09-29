require 'rails_helper'

RSpec.describe "collections/show.html.erb", type: :view do
  let(:collection) { FactoryGirl.create(:collection, :test_data) }
  let(:user) { FactoryGirl.create(:admin_user) }

  before {
    view.class.send :define_method, :blacklight_config, lambda { Blacklight::Configuration.new }
    assign(:collection, collection)
    assign(:id, collection.id)
    assign(:presenter, Sufia::CollectionPresenter.new(collection) )
    assign(:model_class, "collection")
    assign(:events, [])
    assign(:response, double('response').tap do |response|
      allow(response).to receive(:total_pages).and_return(1)
    end)
    controller.request.path_parameters[:id] = collection.id

    sign_in user
  }

  let(:page) { Capybara::Node::Simple.new(rendered) }

  it "renders the page" do
    render
  end
end
