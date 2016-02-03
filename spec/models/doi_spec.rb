require 'rails_helper'

RSpec.describe "doi concern" do
  context "basic methods" do
    let(:file) { FactoryGirl.create(:generic_file, :test_data, :public_doi) }

    describe "#doi_field_readonly?" do
      it "protects doi fields" do
        expect(file.doi_field_readonly?(:title,nil)).to eql(true)
        expect(file.doi_field_readonly?(:contributors,nil)).to eql(true)
        expect(file.doi_field_readonly?(:identifier,file.full_mock_doi)).to eql(true)
        expect(file.doi_field_readonly?(:identifier,'test:12345')).to eql(false)
      end
      it "doesn't care about override" do
        file.doi_protection_override!
        expect(file.doi_field_readonly?(:title,nil)).to eql(true)
        expect(file.doi_field_readonly?(:contributors,nil)).to eql(true)
        expect(file.doi_field_readonly?(:identifier,file.full_mock_doi)).to eql(true)
        expect(file.doi_field_readonly?(:identifier,'test:12345')).to eql(false)
      end
    end

    describe "#field_readonly?" do
      it "delegates to #doi_field_readonly?" do
        expect(file).to receive(:doi_field_readonly?).with(:foo,:bar).and_return(true)
        expect(file.field_readonly?(:foo,:bar)).to eql(true)
      end
      it "returns false if overridden" do
        file.doi_protection_override!
        expect(file).not_to receive(:doi_field_readonly?)
        expect(file.field_readonly?(:title,nil)).to eql(false)
      end
    end

    describe "#mock_doi" do
      subject { file.mock_doi }
      it { is_expected.to match(/\A[0-9]+\.[0-9]+\/[[:alnum:]]{,20}\Z/) }
    end
    describe "#full_mock_doi" do
      subject { file.full_mock_doi }
      it { is_expected.to match(/\Adoi:[0-9]+\.[0-9]+\/[[:alnum:]]{,20}\Z/) }
    end

    describe "#doi_landing_page" do
      subject { file.doi_landing_page }
      it { is_expected.to match("files/#{file.id}")}
    end

    describe "#restricted_mandatory_datacite_fields" do
      subject { file.restricted_mandatory_datacite_fields }
      it "should return fields in the right format" do
        expect(subject).to be_a(Array)
        expect(subject).not_to be_empty
        expect(subject).to all( be_a(Hash) )
        expect(subject).to all( include( :source ) )
        expect(subject).to all( include( :dest ) )
      end
    end

    describe "#guess_identifier_type" do
      # An empty file is good enough for these tests and is much faster.
      subject { (GenericFile.new).guess_identifier_type test_identifier }
      context "with doi prefix" do
        let(:test_identifier) { 'doi:12.3456/abc123456' }
        it { is_expected.to eql( { id_type: 'DOI', id: '12.3456/abc123456' } ) }
      end
      context "with info:doi uri" do
        let(:test_identifier) { 'info:doi/12.3456/abc123456' }
        it { is_expected.to eql( { id_type: 'DOI', id: '12.3456/abc123456' } ) }
      end
      context "with dx.doi.org url" do
        let(:test_identifier) { 'http://dx.doi.org/12.3456/abc123456' }
        it { is_expected.to eql( { id_type: 'DOI', id: '12.3456/abc123456' } ) }
      end
      context "with arxiv prefix" do
        let(:test_identifier) { 'arxiv:1234.123456' }
        it { is_expected.to eql( { id_type: 'arXiv', id: 'arXiv:1234.123456' } ) }
      end
      context "with arxiv url" do
        let(:test_identifier) { 'http://www.arxiv.org/abs/1234.123456' }
        it { is_expected.to eql( { id_type: 'arXiv', id: 'arXiv:1234.123456' } ) }
      end
      context "with urn:lsid prefix" do
        let(:test_identifier) { 'urn:lsid:1234.123456' }
        it { is_expected.to eql( { id_type: 'LSID', id: 'urn:lsid:1234.123456' } ) }
      end
      context "with urn: prefix" do
        let(:test_identifier) { 'urn:1234.123456' }
        it { is_expected.to eql( { id_type: 'URN', id: 'urn:1234.123456' } ) }
      end
      context "with isbn: prefix" do
        let(:test_identifier) { 'isbn:1234-1234-123456' }
        it { is_expected.to eql( { id_type: 'ISBN', id: '1234-1234-123456' } ) }
      end
    end

    describe "#datacite_metadata_changed?" do
      before {
        file.datacite_document = file.doi_metadata.to_json
      }
      subject { file.datacite_metadata_changed? }
      context "when not changed" do
        it { is_expected.to eql(false) }
        context "if something else has changed" do
          before { file.depositor = "testtest" }
          it { is_expected.to eql(false) }
        end
      end
      context "when subject changed" do
        before { file.subject << 'new subject' }
        it { is_expected.to eql(true) }
      end
      context "when contributors changed" do
        before {
          contributor_3_id = (file.contributors.to_a.select do |x|
                                x.contributor_name.first=='Contributor 3'
                              end).first.id
          file.contributors_attributes = [ {id: contributor_3_id, _destroy: 1} ]
        }
        it { is_expected.to eql(true) }
      end
    end
  end


  describe "queue management" do
    let(:file) { FactoryGirl.create(:generic_file) }
    context "when not managed in DataCite" do
      it "assert not managed in DataCite" do
        expect(file.manage_datacite?).to eql( false )
      end
      context "when updating only" do
        it "should not start a DataCite job" do
          expect(Sufia.queue).not_to receive(:push).with(UpdateDataciteJob)
          file.queue_doi_metadata_update 'testuser'
        end
      end
      context "when minting" do
        it "should start a DataCite job" do
          expect(Sufia.queue).to receive(:push).with(UpdateDataciteJob).once
          file.queue_doi_metadata_update 'testuser', mint: true
        end
      end
      context "when destroying" do
        it "should not start a DataCite job" do
          expect(Sufia.queue).not_to receive(:push).with(UpdateDataciteJob)
          file.queue_doi_metadata_update 'testuser', destroyed: true
        end
      end
    end
    context "when managed in DataCite" do
      before { file.add_doi }
      it "assert is managed in DataCite" do
        expect(file.manage_datacite?).to eql( true )
      end
      context "when updating only" do
        it "should start a DataCite job" do
          expect(Sufia.queue).to receive(:push).with(UpdateDataciteJob).once
          file.queue_doi_metadata_update 'testuser'
        end
      end
      # DataCite destroy not yet implemented
      xcontext "when destroying" do
        it "should start a DataCite job" do
          expect(Sufia.queue).to receive(:push).with(UpdateDataciteJob).once
          file.queue_doi_metadata_update 'testuser', destroyed: true
        end
      end
    end
  end

  context "with a generic file" do
    let(:file) { FactoryGirl.create(:generic_file) }

    subject { file }

    context "when it doesn't have a local DOI" do
      it "shouldn't have the DOI in identifiers" do
        expect(subject.identifier).not_to include(file.full_mock_doi)
      end

      it "should not have local doi" do
        expect(subject.has_local_doi?).to eql(false)
      end
      it "should not be managed in datacite" do
        expect(subject.manage_datacite?).to eql(false)
      end
      context "but has outside DOI" do
        before { file.identifier << (file.full_mock_doi+'xx') }
        it "should not have local doi" do
          expect(subject.has_local_doi?).to eql(false)
        end
        it "should not be managed in datacite" do
          expect(subject.manage_datacite?).to eql(false)
        end
        it "should have some doi" do
          expect(subject.has_doi?).to eql(true)
        end
      end
    end

    context "when it does have a local DOI" do
      before { file.add_doi }
      it "adding doi should work" do
        expect(subject.identifier).to include(file.full_mock_doi)
      end

      it "should have local doi" do
        expect(subject.has_local_doi?).to eql(true)
      end
      it "should be managed in datacite" do
        expect(subject.manage_datacite?).to eql(true)
      end
      it "should be managed in datacite" do
        expect(subject.manage_datacite?).to eql(true)
      end
    end

    describe "validation" do
      let(:file) { FactoryGirl.create(:generic_file, :test_data) }
      subject { file }

      context "when not having a published doi" do
        it { is_expected.to be_valid }

        context "with a doi_published set" do
          before { file.doi_published = DateTime.now }
          it { is_expected.not_to be_valid }
        end

        context "with a datacite_document set" do
          before { file.datacite_document = file.doi_metadata.to_json }
          it { is_expected.not_to be_valid }
        end
      end

      context "with published doi but not mandatory fields" do
        before {
          file.identifier += [file.full_mock_doi]
        }
        it { is_expected.not_to be_valid }
      end

      context "when having a published doi" do
        before {
          file.identifier += [file.full_mock_doi]
          file.doi_published = DateTime.parse('Thu, 16 Jul 2015 12:44:38 +0100')
          file.datacite_document = file.doi_metadata.to_json

          file.skip_update_datacite = true
          begin
            file.save
          ensure
            file.skip_update_datacite = false
          end
        }

        it { is_expected.to be_valid }

        it "doesn't let you modify doi_published" do
          file.doi_published = DateTime.now
          expect(file).not_to be_valid
        end

        it "doesn't let you remove doi" do
          file.identifier -= [file.full_mock_doi]
          expect(file).not_to be_valid
        end

        it "doesn't let you change title" do
          file.title = ['Changed title']
          expect(file).not_to be_valid
        end

        it "doesn't let you change creators" do
          contributor_2_id = (file.contributors.to_a.select do |x|
                                x.contributor_name.first=='Contributor 2'
                              end).first.id
          file.contributors_attributes = [ {id: contributor_2_id, _destroy: 1} ]
          expect(file).not_to be_valid
        end

        context "when protection is overridden" do
          before { file.doi_protection_override! }
          it "lets you change anything" do
            file.doi_published = DateTime.now
            file.identifier -= [file.full_mock_doi]
            file.title = ['Changed title']
            contributor_2_id = (file.contributors.to_a.select do |x|
                                  x.contributor_name.first=='Contributor 2'
                                end).first.id
            file.contributors_attributes = [ {id: contributor_2_id, _destroy: 1} ]
            expect(file).to be_valid
          end
        end
      end

    end

    describe "metadata" do
      # TODO: Use an actual file

      let(:file) { FactoryGirl.create(:public_file, :test_data, :public_doi) }

      context "with passing values" do
        it "should not have any metadata errors" do
          expect(file.validate_doi_metadata).to be_empty
        end
        it "should give correct metadata hash" do
          expect(multi_value_sort(file.doi_metadata)).to eql(multi_value_sort(
            {:identifier=>file.mock_doi, :publication_year=>"#{Time.new.year}", :subject=>[{:scheme=>"FAST", :schemeURI=>"http://fast.oclc.org/", :label=>"subject1"}, {:scheme=>"FAST", :schemeURI=>"http://fast.oclc.org/", :label=>"subject2"}, {:scheme=>nil, :schemeURI=>nil, :label=>"keyword1"}, {:scheme=>nil, :schemeURI=>nil, :label=>"keyword2"}], :creator=>[{:name=>"Contributor 1", :affiliation=>["Affiliation 1","Affiliation 1/2"]}, {:name=>"Contributor 2", :affiliation=>["Affiliation 2"]}], :abstract=>["Test abstract"], :research_methods=>["Test research method 1", "Test research method 2"], :funder=>["Funder 1"], :contributor=>[{:name=>"Contributor 3", :affiliation=>["Affiliation 3"], :contributor_type=>"Editor"}], :relatedIdentifier=>[{:id=>"http://related.url.com/test", :id_type=>"URL", :relation_type=>"IsCitedBy"}], :title=>["Test title"], :description=>["Description"], :resource_type=>"Image", :size=>[nil], :format=>["text/plain"], :date_uploaded=>"2015-07-16", :rights=>[{:rights=>"Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International (CC BY-NC-SA)", :rightsURI=>"http://creativecommons.org/licenses/by-nc-sa/4.0/"}]}
          ))
        end
      end

      context "with deleted contributor" do
        before {
          contributor_2_id = (file.contributors.to_a.select do |x|
                                x.contributor_name.first=='Contributor 2'
                              end).first.id
          contributor_3_id = (file.contributors.to_a.select do |x|
                                x.contributor_name.first=='Contributor 3'
                              end).first.id
          file.contributors_attributes = [ {id: contributor_2_id, _destroy: 1}, {id: contributor_3_id, _destroy: 1} ]
        }
        it "should give correct metadata hash" do
          expect(multi_value_sort(file.doi_metadata)).to eql(multi_value_sort(
            {:identifier=>file.mock_doi, :publication_year=>"#{Time.new.year}", :subject=>[{:scheme=>"FAST", :schemeURI=>"http://fast.oclc.org/", :label=>"subject1"}, {:scheme=>"FAST", :schemeURI=>"http://fast.oclc.org/", :label=>"subject2"}, {:scheme=>nil, :schemeURI=>nil, :label=>"keyword1"}, {:scheme=>nil, :schemeURI=>nil, :label=>"keyword2"}], :creator=>[{:name=>"Contributor 1", :affiliation=>["Affiliation 1","Affiliation 1/2"]}], :abstract=>["Test abstract"], :research_methods=>["Test research method 1", "Test research method 2"], :funder=>["Funder 1"], :contributor=>[], :relatedIdentifier=>[{:id=>"http://related.url.com/test", :id_type=>"URL", :relation_type=>"IsCitedBy"}], :title=>["Test title"], :description=>["Description"], :resource_type=>"Image", :size=>[nil], :format=>["text/plain"], :date_uploaded=>"2015-07-16", :rights=>[{:rights=>"Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International (CC BY-NC-SA)", :rightsURI=>"http://creativecommons.org/licenses/by-nc-sa/4.0/"}]}
          ))
        end
      end

      context "with missing required values" do
        context "with wrong visibility" do
          before {
            file.visibility=Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE
          }
          it "assert visibility not public" do
            expect(file.visibility).not_to eql( Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC )
          end
          it "should give a validation error" do
            expect(file.validate_doi_metadata.size).to eql(1)
          end
        end
        context "with no creators" do
          before {
            file.contributors = (file.contributors.to_a.select do |x|
                                  x.role.first!='http://id.loc.gov/vocabulary/relators/cre'
                                end)
          }
          it "should give a validation error" do
            expect(file.validate_doi_metadata.size).to eql(1)
          end
        end
        context "with no title" do
          before {
            file.title=[]
          }
          it "should give a validation error" do
            expect(file.validate_doi_metadata.size).to eql(1)
          end
        end
        context "with no resource type" do
          before {
            file.resource_type=[]
          }
          it "should give a validation error" do
            expect(file.validate_doi_metadata.size).to eql(1)
          end
        end
        context "with multiple errors" do
          before {
            file.contributors=[]
            file.title=[]
            file.resource_type=[]
            file.visibility = Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE
          }
          it "should give a validation error" do
            expect(file.validate_doi_metadata.size).to eql(4)
          end
        end
      end
    end

    describe "#metadata_xml" do
      let(:file) { FactoryGirl.create(:public_file, :test_data, :public_doi) }
      subject { file.doi_metadata_xml }
      it "gives out correct xml" do
        expect(subject).to include('<?xml version="1.0" encoding="UTF-8"?>')
        expect(subject).to include('<resource xmlns="http://datacite.org/schema/kernel-3" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://datacite.org/schema/kernel-3 http://schema.datacite.org/meta/kernel-3/metadata.xsd">')
        expect(subject).to match(/<creator>\s*<creatorName>Contributor 1<\/creatorName>\s*<affiliation>Affiliation 1<\/affiliation>\s*<affiliation>Affiliation 1\/2<\/affiliation>\s*<\/creator>/)
        expect(subject).to match(/<creator>\s*<creatorName>Contributor 2<\/creatorName>\s*<affiliation>Affiliation 2<\/affiliation>\s*<\/creator>/)
        expect(subject).to include('<resourceType resourceTypeGeneral="Image">Image</resourceType>')
        expect(subject).to include('</resource>')
      end
    end

#    context "when part of a collection" do
#      let!(:collection1) { FactoryGirl.create(:collection, :test_data, :public_doi, members: [ file ]) }
#      let!(:collection2) { FactoryGirl.create(:collection, :test_data, members: [ file ]) }
#      before{ file.reload }
#
#      describe "dependent_doi_items" do
#        subject { file.dependent_doi_items }
#        it "returns the dependent collection" do
#          expect(subject.length).to eql(1)
#          expect(subject[0].id).to eql(collection1.id)
#        end
#      end
#
#      describe "updating dependent resources" do
#        it "updating notifies dependent resources" do
#          expect(file.dependent_doi_items[0]).to receive(:queue_doi_metadata_update)
#          file.tag=['Changed tag']
#          file.save
#        end
#
#        it "destroying notifies dependent resources" do
#          expect(file.dependent_doi_items[0]).to receive(:queue_doi_metadata_update)
#          file.destroy
#        end
#      end
#    end
  end

#
#  context "with a collection" do
#    let(:file1) { FactoryGirl.create(:public_file, :test_data) }
#    let(:collection) { FactoryGirl.create(:collection, :test_data, members: [ file1 ]) }
#
#    describe "metadata" do
#      context "with passing values" do
#        it "should not have any metadata errors" do
#          expect(collection.validate_doi_metadata).to be_empty
#        end
#        it "should give correct metadata hash" do
#          expect(multi_value_sort(collection.doi_metadata)).to eql(multi_value_sort(
#            {:identifier=>collection.mock_doi, :publication_year=>"#{Time.new.year}", :subject=>[{:scheme=>"FAST", :schemeURI=>"http://fast.oclc.org/", :label=>"subject1"}, {:scheme=>"FAST", :schemeURI=>"http://fast.oclc.org/", :label=>"subject2"}, {:scheme=>nil, :schemeURI=>nil, :label=>"keyword1"}, {:scheme=>nil, :schemeURI=>nil, :label=>"keyword2"}], :creator=>[{:name=>"Contributor 1", :affiliation=>["Affiliation 1","Affiliation 1/2"]},{:name=>"Contributor 2", :affiliation=>["Affiliation 2"]}], :abstract=>["Test abstract"], :research_methods=>["Test research method 1", "Test research method 2"], :funder=>["Funder 1"], :contributor=>[{:name=>"Contributor 3", :affiliation=>["Affiliation 3"], :contributor_type=>"Editor"}], :relatedIdentifier=>[{:id=>"http://related.url.com/test", :id_type=>"URL", :relation_type=>"IsCitedBy"}], :title=>["Test title"], :description=>["Description"], :resource_type=>"Collection", :rights=>[], :format=>[], :size=>[]}
#            {:identifier=>collection.mock_doi, :publication_year=>"#{Time.new.year}", :subject=>[{:scheme=>"FAST", :schemeURI=>"http://fast.oclc.org/", :label=>"subject1"}, {:scheme=>"FAST", :schemeURI=>"http://fast.oclc.org/", :label=>"subject2"}, {:scheme=>nil, :schemeURI=>nil, :label=>"keyword1"}, {:scheme=>nil, :schemeURI=>nil, :label=>"keyword2"}], :creator=>[{:name=>"Contributor 1", :affiliation=>"Affiliation 1"},{:name=>"Contributor 2", :affiliation=>"Affiliation 2"}], :abstract=>["Test abstract"], :research_methods=>["Test research method 1", "Test research method 2"], :funder=>["Funder 1"], :contributor=>[{:name=>"Contributor 3", :affiliation=>"Affiliation 3", :contributor_type=>"Editor"}], :relatedIdentifier=>[{:id=>file1.doi_landing_page, :id_type=>"URL", :relation_type=>"HasPart"},{:id=>"http://related.url.com/test", :id_type=>"URL", :relation_type=>"IsCitedBy"}], :title=>["Test title"], :description=>["Description"], :resource_type=>"Collection", :rights=>[{:rights=>"#{file1.id} - Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International (CC BY-NC-SA)", :rightsURI=>"http://creativecommons.org/licenses/by-nc-sa/4.0/"}], :format=>["#{file1.id} - text/plain"], :size=>["#{file1.id} - "]}
#          ))
#        end
#      end
#    end
#  end
end
