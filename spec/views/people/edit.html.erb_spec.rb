require 'rails_helper'

RSpec.describe "people/edit", type: :view do
  before(:each) do
    @person = assign(:person, Person.create!(
      :full_name => "MyString",
      :orcid => "MyString",
      :cis_username => "MyString",
      :affiliation => "MyString"
    ))
  end

  it "renders the edit person form" do
    render

    assert_select "form[action=?][method=?]", person_path(@person), "post" do

      assert_select "input#person_full_name[name=?]", "person[full_name]"

      assert_select "input#person_orcid[name=?]", "person[orcid]"

      assert_select "input#person_cis_username[name=?]", "person[cis_username]"

      assert_select "input#person_affiliation[name=?]", "person[affiliation]"
    end
  end
end
