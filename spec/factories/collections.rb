FactoryGirl.define do
  factory :collection do
    title 'Test Collection'
    tag ['test tag']
    contributors { [FactoryGirl.build(:contributor)] }

    transient do
      depositor { FactoryGirl.create :user }
    end
    before(:create) do |c, evaluator|
      c.apply_depositor_metadata evaluator.depositor
    end

    read_groups ['public']
    resource_type ['Collection']

    trait :public_doi do
      after(:create) do |c, evaluator|
        c.identifier += [c.full_mock_doi]
        c.doi_published = DateTime.now
        c.datacite_document = c.doi_metadata.to_json
        c.skip_update_datacite = true
        c.save
      end
    end

    trait :test_data do
      title 'Test title'
      identifier ['isbn:123456', 'arXiv:0123.0000', 'http://something.else.com']
      abstract ['Test abstract']
      research_methods ['Test research method 1', 'Test research method 2']
      funder ['Funder 1']
      tag ['keyword1', 'keyword2']
      subject ['subject1', 'subject2']
      related_url ['http://related.url.com/test']
      description ['Description']
      date_uploaded DateTime.parse('Thu, 16 Jul 2015 12:44:38 +0100')

      contributors { [
        FactoryGirl.build(:contributor, contributor_name: ['Contributor 1'],
                                        affiliation: ['Affiliation 1'],
                                        role: ['http://id.loc.gov/vocabulary/relators/cre']),
        FactoryGirl.build(:contributor, contributor_name: ['Contributor 2'],
                                        affiliation: ['Affiliation 2'],
                                        role: ['http://id.loc.gov/vocabulary/relators/cre']),
        FactoryGirl.build(:contributor, contributor_name: ['Contributor 3'],
                                        affiliation: ['Affiliation 3'],
                                        role: ['http://id.loc.gov/vocabulary/relators/edt'])
      ] }

    end
  end
end
