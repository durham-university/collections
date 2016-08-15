require 'rails_helper'

RSpec.describe "Uploading a file", type: :feature do
  let(:user) { FactoryGirl.create(:user) }
  let(:file) { File.join(fixture_path,'test.pdf') }
  before { sign_in user }

  it "Can upload a file" do
    # Go to upload form and fill in form
    visit new_generic_file_path
    check 'terms_of_service'
    attach_file 'files[]', file
    batch_id = page.find("input[name='batch_id']").value
    page.find('#main_upload_start').click

    # Usually previous click is captured by javascript and upload is done in
    # background. In here we have to manually move to the batch edit page.
    # There seems to be a conflict with batch_edit_path so we need to create
    # the url manually.
    visit "batches/#{batch_id}/edit"

    # Set metadata values in batch edit form
    expect(page).to have_content('Apply Metadata')
    expect(page.find('#generic_file_title').value).to eql 'test.pdf'
    title_input_name = page.find('#generic_file_title')['name']
    file_id = title_input_name.scan(/title\[([^\]]*)\]\[\]/)[0][0]
    expect(file_id).to be_present
    fill_in title_input_name, with: 'Testing file upload title'
    select 'Other', from: 'generic_file[resource_type][]'
    fill_in 'generic_file[contributors_attributes][0][contributor_name][]', with: 'Test contributor'
    fill_in 'generic_file[contributors_attributes][0][affiliation][]', with: 'Test affiliation'

    # Save metadata and move to file list
    page.find("#upload_submit").click

    expect(page).to have_content('Your files are being processed')
    within "#document_#{file_id}" do
      # Ordinarily the title would be set by the background job but in tests they
      # are ran immediately so we can test for the set title right away.
      expect(page).to have_content('Testing file upload title')
      expect(page).to have_selector("a[href='#{generic_file_path(file_id)}']")
      expect(page).to have_selector("a[href='#{edit_generic_file_path(file_id)}']")
      expect(page).to have_content('Private')
    end

    # Move to file page
    visit generic_file_path(file_id)
    within '.file-show-descriptions' do
      expect(page).to have_content('Test contributor')
      expect(page).to have_content('Test affiliation')
    end
    within '.file-show-details' do
      expect(page).to have_content('Mime type: application/pdf')
      expect(page).to have_content('Filename: test.pdf')
    end
    expect(page).to have_selector("a[href='/downloads/#{file_id}']")
    expect(page).to have_selector("img[src='/downloads/#{file_id}?file=thumbnail']")

    # make sure the thumbnail is ok
    visit "/downloads/#{file_id}?file=thumbnail'"
    expect(page.status_code).to eql 200

    # make sure the file itself is ok
    visit "/downloads/#{file_id}"
    expect(page.status_code).to eql 200
    expect(page.response_headers['Content-Type']).to eql 'application/pdf'
    expect(page.response_headers['Content-Disposition']).to include 'test'
    expect(page.response_headers['Content-Disposition']).to include '.pdf'
  end
end
