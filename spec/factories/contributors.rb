FactoryGirl.define do
  factory :contributor do
    sequence(:contributor_name) { |n| ["Test Contributor #{n}"] }
    sequence(:affiliation) { |n| ["Test Affiliation #{n}"] }

    role ['http://id.loc.gov/vocabulary/relators/cre']
  end
end
