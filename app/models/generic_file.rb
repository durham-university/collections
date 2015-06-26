class GenericFile < ActiveFedora::Base
  include Sufia::GenericFile
  include HydraDurham::AccessControls
  include HydraDurham::Metadata
  include HydraDurham::Doi
end
