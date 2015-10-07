require 'rails_helper'
require 'shared/ordered_property'

RSpec.describe "ordered property" do
  it_behaves_like "ordered property" do
    let( :macro ) { :ordered_property }
    let( :concern ) { HydraDurham::OrderedProperty.to_s }
    let( :wrapper_suffix ) { '_with_order' }
  end
end
