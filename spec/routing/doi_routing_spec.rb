require "rails_helper"

RSpec.describe DoiController, type: :routing do
  describe "routing" do
    it "routes to #show" do
      expect(:get => "/doi/1").to route_to("doi#show", :id => "1")
    end

    it "routes to #update" do
      expect(:put => "/doi/1").to route_to("doi#update", :id => "1")
    end

  end
end
