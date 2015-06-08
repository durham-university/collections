require 'rails_helper'

RSpec.describe "people/index", type: :view do
  before(:each) do
    assign(:people, [
      Person.create!(
        :full_name => "Full Name",
        :orcid => "Orcid",
        :cis_username => "Cis Username",
        :affiliation => "Affiliation"
      ),
      Person.create!(
        :full_name => "Full Name",
        :orcid => "Orcid",
        :cis_username => "Cis Username",
        :affiliation => "Affiliation"
      )
    ])
  end

  it "renders a list of people" do
    render
    assert_select "tr>td", :text => "Full Name".to_s, :count => 2
    assert_select "tr>td", :text => "Orcid".to_s, :count => 2
    assert_select "tr>td", :text => "Cis Username".to_s, :count => 2
    assert_select "tr>td", :text => "Affiliation".to_s, :count => 2
  end
end
