require 'rails_helper'

RSpec.describe "metadata concern" do
  let(:file) { FactoryGirl.create(:generic_file) }
  let(:file_saved) {
    file.save if file.changed_for_autosave?
    file
  }
  let(:file_fedora) { GenericFile.find(file_saved.id) }
  let(:file_solr) { GenericFile.load_instance_from_solr(file_saved.id) }

  describe "added properties" do
    subject { file }

    it { is_expected.to respond_to :funder }
    it { is_expected.to respond_to :abstract }
    it { is_expected.to respond_to :research_methods }
  end

  describe "setting abstract" do
    before { file.abstract = ["Test abstract"] }
    subject { file.abstract }
    it { is_expected.to eql ["Test abstract"] }
  end

  describe "contributors" do
    let(:contributor_1_attrs) { {contributor_name: ["Contributor 1"], affiliation: ["Affiliation 1"], role: ['http://id.loc.gov/vocabulary/relators/cre']} }
    let(:contributor_2_attrs) { {contributor_name: ["Contributor 2"], affiliation: ["Affiliation 2"], role: ['http://id.loc.gov/vocabulary/relators/edt']} }

    subject { file.contributors }
    it { is_expected.to be_empty }

    context "modifying nested attributes" do
      describe "adding a contributor" do
        before { file.contributors_attributes = [ contributor_1_attrs ] }
        subject { file.contributors }
        it "should have one contributor" do
          expect(subject.size).to eql( 1 )
        end
        it "should have the right name, affiliation and role" do
          expect(subject.first.to_hash).to eql( contributor_1_attrs )
        end
      end

      describe "adding several contributors" do
        describe "separately" do
          before {
            file.contributors_attributes = [ contributor_1_attrs ]
            file.contributors_attributes = [ contributor_2_attrs ]
          }
          it "should have two contributors" do
            expect(subject.size).to eql( 2 )
          end
          it "should have the right names, affiliations and roles" do
            expect(subject.map &:to_hash).to eql( [contributor_1_attrs, contributor_2_attrs] )
          end
        end

        describe "in one go" do
          before {
            file.contributors_attributes = [ contributor_1_attrs, contributor_2_attrs ]
          }
          it "should have two contributors" do
            expect(subject.size).to eql( 2 )
          end
          it "should have the right names, affiliations and roles" do
            expect(subject.map &:to_hash).to eql( [contributor_1_attrs, contributor_2_attrs] )
          end
        end
      end

      describe "persisting contributors" do
        before {
          file.contributors_attributes = [ contributor_1_attrs, contributor_2_attrs ]
        }
        describe "in Fedora" do
          subject { file_fedora.contributors }
          it "should have two contributors" do
            expect(subject.size).to eql( 2 )
          end
          it "should have the right names, affiliations and roles" do
            expect(subject.map &:to_hash).to eql( [contributor_1_attrs, contributor_2_attrs] )
          end
        end
        describe "in Solr" do
          subject { file_solr.contributors }

          it "should load contributors from solr" do
            expect(file_solr.association(:contributors).loaded?).to be_truthy
          end

          it "should have two contributors" do
            expect(subject.size).to eql( 2 )
          end
          it "should have the right names, affiliations and roles" do
            expect(subject.map &:to_hash).to eql( [contributor_1_attrs, contributor_2_attrs] )
          end
        end
      end

      describe "removing contributors" do
        before {
          file.contributors_attributes = [ contributor_1_attrs, contributor_2_attrs ]
          file.save
          contributor_1_id = (file.contributors.to_a.select do |x|
                                x.contributor_name==contributor_1_attrs[:contributor_name]
                              end).first.id
          file.contributors_attributes = [ {id: contributor_1_id, _destroy: 1} ]
          file.save
        }
        it "should have only one contributor" do
          expect(subject.size).to eql( 1 )
        end
        it "should have the the right name, affiliation and role for the remaining contributor" do
          expect(subject.map &:to_hash).to eql( [contributor_2_attrs] )
        end
      end
    end

    describe "indexing" do
      before {
        file.contributors_attributes = [ contributor_1_attrs, contributor_2_attrs ]
      }
      subject { file.to_solr }
      it "should have contributors in solr document" do
        expect(subject['contributors_tesim']).to eql( [
              "#{contributor_1_attrs[:contributor_name].first} (#{contributor_1_attrs[:affiliation].first})",
              "#{contributor_2_attrs[:contributor_name].first} (#{contributor_2_attrs[:affiliation].first})"
            ])
        expect(subject['contributors_sim']).to eql( [
              "#{contributor_1_attrs[:contributor_name].first} (#{contributor_1_attrs[:affiliation].first})",
              "#{contributor_2_attrs[:contributor_name].first} (#{contributor_2_attrs[:affiliation].first})"
            ])
      end

      context "when removing a contributor" do
        before {
          file.save
          contributor_1_id = (file.contributors.to_a.select do |x|
                                x.contributor_name==contributor_1_attrs[:contributor_name]
                              end).first.id
          file.contributors_attributes = [ {id: contributor_1_id, _destroy: 1} ]
        }
        subject { file.to_solr }
        it "should only have one contributor remaining" do
          expect(subject['contributors_tesim']).to eql( [
                "#{contributor_2_attrs[:contributor_name].first} (#{contributor_2_attrs[:affiliation].first})"
              ])
          expect(subject['contributors_sim']).to eql( [
                "#{contributor_2_attrs[:contributor_name].first} (#{contributor_2_attrs[:affiliation].first})"
              ])

        end
      end
    end
  end

end
