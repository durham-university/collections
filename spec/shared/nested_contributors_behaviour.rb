require 'rails_helper'

RSpec.shared_examples "nested_contributors_behaviour" do

  # Pass let(:resource) { FactoryGirl.create(...) } to this shared example group.
  # Sign in user so they can modify the resource.
  # You can pass params too if you need to add other post parameters.

  let(:params) { { id: resource.id } }
  let(:contributor) { resource.contributors_sorted[0] }
  let(:expected_contributors_count) { resource.contributors_sorted.count }
  it "deserialises multi-value affiliations" do
    params[ resource.class.to_s.underscore.to_sym ] = {
      contributors_attributes: [{
        id: contributor.id,
        contributor_name: contributor.contributor_name.to_a,
        affiliation: ['New Affiliation; Second New Affiliation'],
        order: contributor.order.to_a,
        role: contributor.role.to_a
      }]
    }
    expected_contributors_count # init this variable before posting
    post :update, params
    resource.reload
    expect(resource.contributors.count).to eql( expected_contributors_count )
    # match_array ignores ordering
    expect(resource.contributors_sorted[0].affiliation).to match_array(['New Affiliation', 'Second New Affiliation'])
    expect(resource.contributors_sorted[0].contributor_name).to be_present
  end
  
  it "removes blank roles" do
    params[ resource.class.to_s.underscore.to_sym ] = {
      contributors_attributes: [{
        id: contributor.id,
        contributor_name: contributor.contributor_name.to_a,
        affiliation: contributor.affiliation.to_a,
        order: contributor.order.to_a,
        role: [''] + contributor.role.to_a
      }]
    }
    expected_contributors_count # init this variable before posting
    post :update, params
    resource.reload
    expect(resource.contributors_sorted[0].role.count).to eql(1)
  end
end
