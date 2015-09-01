require 'rails_helper'

RSpec.describe 'ContributorWithHelpInput', type: :input do
  let(:file) { FactoryGirl.create(:generic_file, :test_data) }
  let(:input) { input_for file, :contributors, as: :contributor_with_help }
  let(:node) { Capybara::Node::Simple.new(input) }

  it "should have all contributors" do
    # file has three contributors, there should be four values, one is empty for a new contributor
    expect(file.contributors.count).to eql(3)
    expect(input).to have_selector('.form-group.contributors_multi_value ul.listing>li', count: 4)
  end

  it "should have all contributor fields" do
    first_contributor = node.find(:css,'.form-group.contributors_multi_value ul.listing>li:first-child')
    expect(first_contributor).to have_selector("input[name='generic_file[contributors_attributes][0][contributor_name][]']")
    expect(first_contributor).to have_selector("input[name='generic_file[contributors_attributes][0][affiliation][]']")
    expect(first_contributor).to have_selector("select[name='generic_file[contributors_attributes][0][role][]']")
    expect(first_contributor).to have_selector("input[name='generic_file[contributors_attributes][0][order][]']")
    expect(first_contributor).to have_selector("input[name='generic_file[contributors_attributes][0][id]']")
  end

  it "should join multiple affiliations" do
    expect(file.contributors_sorted[0].affiliation.count).to be > 1
    first_contributor = node.find(:css,'.form-group.contributors_multi_value ul.listing>li:first-child')
    expect(first_contributor).to have_selector("input[name='generic_file[contributors_attributes][0][affiliation][]'][value='#{file.contributors_sorted[0].affiliation.join('; ')}']",)
  end
end
