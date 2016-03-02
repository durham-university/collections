require 'rails_helper'

RSpec.describe "generic_files/edit.html.erb", type: :view do
  let(:file) { FactoryGirl.create(:generic_file, :test_data) }
  let(:user) { FactoryGirl.create(:admin_user) }

  before {
    view.class.send :define_method, :blacklight_config, lambda { Blacklight::Configuration.new }
    assign(:generic_file, file)
    assign(:id, file.id)
    assign(:form, Sufia::Forms::GenericFileEditForm.new(file) )
    assign(:model_class, "generic_file")
    assign(:events, [])
    assign(:response, double('response').tap do |response|
      allow(response).to receive(:total_pages).and_return(1)
      allow(response).to receive(:total).and_return(0)
      allow(response).to receive(:spelling).and_return(double('spelling').tap do |spelling|
        allow(spelling).to receive(:words).and_return([])
      end)
    end)
    allow(view).to receive(:params).and_return( { controller: 'generic_files'} )
    assign(:version_list,[])
    controller.request.path_parameters[:id] = file.id

    sign_in user
    assign(:current_user, user)
  }

  let(:page) { Capybara::Node::Simple.new(rendered) }

  it "renders the page" do
    render
  end
  
  it "has a delete link" do
    render
    expect(page).to have_selector("a[href='#{generic_file_path(file)}'][data-method='delete']")
  end  
end
