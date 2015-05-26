class GenericFile < ActiveFedora::Base
  include Sufia::GenericFile
  include HydraDurham::Metadata
end
