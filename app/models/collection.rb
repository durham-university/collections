class Collection < Sufia::Collection
  include HydraDurham::Metadata

  validates :resource_type, acceptance: { accept: ['Collection'] }
end
