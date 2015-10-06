require 'rails_helper'

RSpec.describe "batch/edit.html.erb", type: :view do
  let(:batch) { FactoryGirl.create(:batch).tap do |batch|
      batch.generic_files.each do |file|
        allow(file).to receive(:label).and_return(file.title.first)
      end
    end
  }
  let(:file) {
    GenericFile.new(creator: [user.to_param], title: batch.generic_files.map(&:label))
  }
  let(:user) { FactoryGirl.create(:admin_user) }

  before {
    view.class.send :define_method, :blacklight_config, lambda { Blacklight::Configuration.new }
    assign(:batch, batch)
    assign(:form, Sufia::Forms::BatchEditForm.new(file) )
    allow(view).to receive(:params).and_return( { controller: 'batch'} )
    controller.request.path_parameters[:id] = batch.id

    sign_in user
  }

  let(:page) { Capybara::Node::Simple.new(rendered) }

  it "renders the page" do
    render
  end
end
