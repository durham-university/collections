require 'rails_helper'

RSpec.describe "people/show", type: :view do
  before(:each) do
    @person = assign(:person, Person.create!(
      :full_name => "Full Name",
      :orcid => "Orcid",
      :cis_username => "Cis Username",
      :affiliation => "Affiliation"
    ))
  end

  it "renders attributes in <p>" do
    render
    expect(rendered).to match(/Full Name/)
    expect(rendered).to match(/Orcid/)
    expect(rendered).to match(/Cis Username/)
    expect(rendered).to match(/Affiliation/)
  end
end
