class Collection < Sufia::Collection
  include HydraDurham::Metadata
  include HydraDurham::Doi

  validates :resource_type, acceptance: { accept: ['Collection'] }
end
