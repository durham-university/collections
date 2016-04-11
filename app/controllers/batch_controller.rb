class BatchController < ApplicationController
  include Sufia::BatchControllerBehavior
  include HydraDurham::NestedContributorsBehaviour  
end