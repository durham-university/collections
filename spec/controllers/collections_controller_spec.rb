require 'rails_helper'
#require 'shared/doi_resource_behaviour'
require 'shared/nested_contributors_behaviour'

RSpec.describe CollectionsController do
  routes { Hydra::Collections::Engine.routes }
  let(:user) { FactoryGirl.find_or_create(:user) }
  before { sign_in user }

  #it_behaves_like "doi_resource_behaviour" do
  #  let(:resource_factory) { :collection }
  #end

  it_behaves_like "nested_contributors_behaviour" do
    let(:resource) { FactoryGirl.create(:collection,:test_data,depositor: user) }
  end

  describe "update" do
    let(:collection) { FactoryGirl.create(:collection,:test_data,depositor: user) }

    context "when adding a title" do
      let(:attributes) { { title: 'My Favorite Things' } }
      before { post :update, id: collection.id, collection: attributes }
      subject { collection.reload.title }
      it { is_expected.to eq "My Favorite Things" }
    end

    context "when adding a contributor" do
      let(:attributes) {
        {
          contributors_attributes: [ { contributor_name: ['John'], affiliation: ['Coltrane'], role: ['http://id.loc.gov/vocabulary/relators/edt'], order: ["100"] } ]
        }
      }

      before { post :update, id: collection.id, collection: attributes }
      subject { collection.reload }

      it "sets the values using the parameters hash" do
        expect(subject.contributors_sorted.last.contributor_name).to eq ["John"]
        expect(subject.contributors_sorted.last.affiliation).to eq ["Coltrane"]
        expect(subject.contributors_sorted.last.role).to eq ["http://id.loc.gov/vocabulary/relators/edt"]
        expect(subject.contributors_sorted.last.order).to eq ['100']
      end
    end

    context "when removing a contributor" do
      let(:attributes) {
        {
          contributors_attributes: [ { id: collection.contributors_sorted[1].id, _destroy: 1 } ]
        }
      }

      before {
        @deleted_contributor = collection.contributors_sorted[1]
        @old_size = collection.contributors.count
        post :update, id: collection.id, collection: attributes
      }
      subject { collection.reload }

      it "removes the contributor" do
        expect(subject.contributors.count).to eql(@old_size-1)
        expect(subject.contributors_sorted[1].contributor_name.first).not_to eql(@deleted_contributor.contributor_name.first)
      end
    end

    context "when reordering contributors" do
      let(:attributes) {
        {
          contributors_attributes: collection.contributors.map do |c|
            { id: c.id, contributor_name: [c.contributor_name.first], affiliation: [c.affiliation.first], role: [c.role.first], order: ["#{(c.order.first.to_i+1) % (collection.contributors.count)}"]}
          end
        }
      }

      before {
        @old_contributors = collection.contributors_sorted
        @old_size = collection.contributors.count
        post :update, id: collection.id, collection: attributes
      }
      subject { collection.reload }

      it "sets the new ordering values" do
        expect(subject.contributors.count).to eql(@old_size)
        (0..(@old_size-1)).each do |i|
          expect(subject.contributors_sorted[i].to_hash).to eql(@old_contributors[(i+1) % (@old_size)].to_hash)
        end
      end
    end
  end
end
