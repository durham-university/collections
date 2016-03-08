require "rails_helper"

RSpec.describe IdentifiersController, type: :routing do
  describe "routing" do
    it "routes arks to #show" do
      expect(:get => "/id/ark:/12345/123456").to route_to("identifiers#show", id: "ark:/12345/123456")
      expect(:get => "/id/ark:/12345/123456.json").to route_to("identifiers#show", id: "ark:/12345/123456", format: 'json')
    end
    
    it "routes dois to #show" do
      expect(:get => "/id/doi:10.12345/abcdeg").to route_to("identifiers#show", id: "doi:10.12345/abcdeg")
      expect(:get => "/id/doi:10.12345/abcdeg.json").to route_to("identifiers#show", id: "doi:10.12345/abcdeg", format: 'json')
    end

  end
end
