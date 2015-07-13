class Collection < Sufia::Collection
  include HydraDurham::Metadata
  include HydraDurham::Doi

  # title validation already in hydra-collection
  validates :contributors, presence: true
  validates :tag, presence: true
  validates :rights, presence: true
  validates :resource_type, presence: true
  validates :resource_type, acceptance: { allow_nil: false, accept: ['Collection'] }
end
