class Collection < Sufia::Collection
  include HydraDurham::Metadata
  include HydraDurham::ArkBehaviour
  #include HydraDurham::Doi

  # title validation already in hydra-collection
  validates :contributors, presence: true
  validates :resource_type, presence: true # keep this because collection_edit_form checks mandatory fields by presence validators
  validates :resource_type, acceptance: { allow_nil: false, accept: ['Collection'] }
  
  protected
  
    def file_size_field
      # File size field is overridden to support >2GB file sizes.
      # Solrizer doesn't seem to support long type so hard code field name
      'file_size_ls'
    end
end
