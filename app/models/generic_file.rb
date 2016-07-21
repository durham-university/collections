class GenericFile < ActiveFedora::Base
  include Sufia::GenericFile
  include HydraDurham::AccessControls
  include HydraDurham::Metadata
  include HydraDurham::ArkBehaviour
  include HydraDurham::Doi
  include HydraDurham::IdentifierNormalisation
  include HydraDurham::FedoraBigFieldGuard
  
  private
  
    # don't do full text indexing for very large files
    def extract_content
      return nil if content.size > 100.megabytes
      return super
    end
end
