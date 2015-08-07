require 'rails_helper'

RSpec.describe 'StringInput', type: :input do
  let(:input) { input_for collection, field, as: :multi_value_with_help, required: true }

  context "non-disabled fields" do
    let(:collection) { FactoryGirl.create(:collection, :test_data) }
    let(:field) { :title }
    it "should not be disabled" do
      expect(input).not_to have_selector('ul.readonly_field')
      expect(input).not_to have_selector('li.readonly_field')
      expect(input).not_to have_selector('input[readonly=readonly]')
    end
  end

  context "disabled fields" do
    let(:collection) { FactoryGirl.create(:collection, :test_data, :public_doi) }
    let(:field) { :title }
    it "should be disabled" do
      expect(input).to have_selector('ul.readonly_field')
      expect(input).to have_selector('li.readonly_field')
      expect(input).to have_selector('input[readonly=readonly]')
    end
  end
end
