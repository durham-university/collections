require 'rails_helper'

RSpec.describe "people/new", type: :view do
  before(:each) do
    assign(:person, Person.new(
      :full_name => "MyString",
      :orcid => "MyString",
      :cis_username => "MyString",
      :affiliation => "MyString"
    ))
  end

  it "renders new person form" do
    render

    assert_select "form[action=?][method=?]", people_path, "post" do

      assert_select "input#person_full_name[name=?]", "person[full_name]"

      assert_select "input#person_orcid[name=?]", "person[orcid]"

      assert_select "input#person_cis_username[name=?]", "person[cis_username]"

      assert_select "input#person_affiliation[name=?]", "person[affiliation]"
    end
  end
end
