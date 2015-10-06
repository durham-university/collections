require 'rails_helper'

def has_all_visibility_options
  expect(page).to have_selector("input#visibility_open")
  expect(page).to have_selector("input#visibility_open_pending")
  expect(page).to have_selector("input#visibility_psu")
  expect(page).to have_selector("input#visibility_restricted")
end

RSpec.describe "generic_files/_permission_form.html.erb", type: :view do
  let(:form) {
    double('form').tap do |form|
      allow(form).to receive(:object).and_return(file)
      allow(form).to receive(:fields_for).and_return('')
    end
  }

  before {
    assign(:current_user, user)
    allow(view).to receive(:params).and_return( { controller: 'generic_files'} )
    render 'generic_files/permission_form', f: form
  }

  let(:page) { Capybara::Node::Simple.new(rendered) }

  context "non-admin user" do
    let(:user) { FactoryGirl.create(:user) }

    context "public file" do
      let(:file) { FactoryGirl.create(:public_file, depositor: user) }
      it "has correct visibility options" do |variable|
        has_all_visibility_options
        expect(page).not_to have_selector("input#visibility_open[disabled='true']")
        expect(page).to have_selector("input#visibility_open_pending[disabled='true']")
        expect(page).to have_selector("input#visibility_psu[disabled='true']")
        expect(page).to have_selector("input#visibility_restricted[disabled='true']")
      end
    end

    context "registered file" do
      let(:file) { FactoryGirl.create(:registered_file, depositor: user) }
      it "has correct visibility options" do |variable|
        has_all_visibility_options
        expect(page).to have_selector("input#visibility_open[disabled='true']")
        expect(page).not_to have_selector("input#visibility_open_pending[disabled='true']")
        expect(page).not_to have_selector("input#visibility_psu[disabled='true']")
        expect(page).not_to have_selector("input#visibility_restricted[disabled='true']")
      end
    end

    context "private file" do
      let(:file) { FactoryGirl.create(:generic_file, depositor: user) }
      it "has correct visibility options" do |variable|
        has_all_visibility_options
        expect(page).to have_selector("input#visibility_open[disabled='true']")
        expect(page).not_to have_selector("input#visibility_open_pending[disabled='true']")
        expect(page).not_to have_selector("input#visibility_psu[disabled='true']")
        expect(page).not_to have_selector("input#visibility_restricted[disabled='true']")
      end
    end
  end

  context "admin user" do
    let(:user) { FactoryGirl.create(:admin_user) }

    context "public file" do
      let(:file) { FactoryGirl.create(:public_file, depositor: user) }
      it "has correct visibility options" do |variable|
        has_all_visibility_options
        expect(page).not_to have_selector("input#visibility_open[disabled='true']")
        expect(page).not_to have_selector("input#visibility_open_pending[disabled='true']")
        expect(page).not_to have_selector("input#visibility_psu[disabled='true']")
        expect(page).not_to have_selector("input#visibility_restricted[disabled='true']")
      end
    end

    context "registered file" do
      let(:file) { FactoryGirl.create(:registered_file, depositor: user) }
      it "has correct visibility options" do |variable|
        has_all_visibility_options
        expect(page).not_to have_selector("input#visibility_open[disabled='true']")
        expect(page).not_to have_selector("input#visibility_open_pending[disabled='true']")
        expect(page).not_to have_selector("input#visibility_psu[disabled='true']")
        expect(page).not_to have_selector("input#visibility_restricted[disabled='true']")
      end
    end

    context "private file" do
      let(:file) { FactoryGirl.create(:generic_file, depositor: user) }
      it "has correct visibility options" do |variable|
        has_all_visibility_options
        expect(page).not_to have_selector("input#visibility_open[disabled='true']")
        expect(page).not_to have_selector("input#visibility_open_pending[disabled='true']")
        expect(page).not_to have_selector("input#visibility_psu[disabled='true']")
        expect(page).not_to have_selector("input#visibility_restricted[disabled='true']")
      end
    end
  end
end
