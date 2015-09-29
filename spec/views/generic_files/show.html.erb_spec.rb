require 'rails_helper'

RSpec.describe "generic_files/show.html.erb", type: :view do
  let(:file) { FactoryGirl.create(:generic_file, :test_data) }
  let(:user) { FactoryGirl.create(:admin_user) }

  before {
    view.class.send :define_method, :blacklight_config, lambda { Blacklight::Configuration.new }
    assign(:generic_file, file)
    assign(:id, file.id)
    assign(:presenter, Sufia::GenericFilePresenter.new(file) )
    assign(:model_class, "generic_file")
    assign(:events, [])
    controller.request.path_parameters[:id] = file.id
    sign_in user
  }

  let(:page) { Capybara::Node::Simple.new(rendered) }

  it "renders the page" do
    render
  end
end
