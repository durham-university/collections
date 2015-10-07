require 'rails_helper'
require 'shared/ordered_property'

RSpec.describe "property with relevance" do
  it_behaves_like "ordered property" do
    let( :macro ) { :property_with_relevance }
    let( :concern ) { HydraDurham::PropertyWithRelevance.to_s }
    let( :wrapper_suffix ) { '_with_relevance' }
  end
end
