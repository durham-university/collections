class Collection < Sufia::Collection
  include HydraDurham::Metadata
  #include HydraDurham::Doi

  # title validation already in hydra-collection
  validates :contributors, presence: true
  validates :resource_type, presence: true # keep this because collection_edit_form checks mandatory fields by presence validators
  validates :resource_type, acceptance: { allow_nil: false, accept: ['Collection'] }
end
