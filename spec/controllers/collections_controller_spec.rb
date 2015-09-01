require 'rails_helper'
require 'shared/doi_resource_behaviour'

RSpec.describe CollectionsController do
  routes { Hydra::Collections::Engine.routes }
  let(:user) { FactoryGirl.find_or_create(:user) }
  before { sign_in user }

  it_behaves_like "doi_resource_behaviour" do
    let(:resource_factory) { :collection }
  end
end
