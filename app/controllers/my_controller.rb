class MyController < ApplicationController
  include Sufia::MyControllerBehavior

  skip_before_filter :find_collections
  before_filter :find_collections_with_edit_access
end
