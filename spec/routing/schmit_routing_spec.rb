require "rails_helper"

RSpec.describe SchmitDownloadsController, type: :routing do
  describe "routing" do
    it "routes id to #show" do
      expect(:get => "/schmit/1").to route_to("schmit_downloads#show", :id => "1")
    end
    it "routes id and format to #show" do
      expect(:get => "/schmit/1.pdf").to route_to("schmit_downloads#show", :id => "1.pdf")
    end
  end
end
