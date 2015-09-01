FactoryGirl.define do
  factory :generic_file do
    contributors []

    transient do
      depositor { FactoryGirl.create :user }
    end
    before(:create) do |gf, evaluator|
      gf.apply_depositor_metadata evaluator.depositor
    end

    factory :public_file do
      read_groups ["public"]
    end

    factory :registered_file do
      read_groups ["registered"]
    end

    trait :public_doi do
      after(:create) do |gf, evaluator|
        gf.identifier += [gf.full_mock_doi]
        gf.doi_published = DateTime.now
        gf.datacite_document = gf.doi_metadata.to_json
        gf.skip_update_datacite = true
        gf.save
      end
    end

    trait :test_data do
      title ['Test title']
      identifier ['isbn:123456', 'arXiv:0123.0000', 'http://something.else.com']
      abstract ['Test abstract']
      research_methods ['Test research method 1', 'Test research method 2']
      funder ['Funder 1']
      tag ['keyword1', 'keyword2']
      subject ['subject1', 'subject2']
      related_url ['http://related.url.com/test']
      description ['Description']
      resource_type ['Image']
      date_uploaded DateTime.parse('Thu, 16 Jul 2015 12:44:38 +0100')
      rights ['http://creativecommons.org/licenses/by-nc-sa/4.0/']

      contributors { [
        FactoryGirl.build(:contributor, contributor_name: ['Contributor 1'],
                                        affiliation: ['Affiliation 1'],
                                        role: ['http://id.loc.gov/vocabulary/relators/cre'],
                                        order: ['1']),
        FactoryGirl.build(:contributor, contributor_name: ['Contributor 2'],
                                        affiliation: ['Affiliation 2'],
                                        role: ['http://id.loc.gov/vocabulary/relators/cre'],
                                        order: ['2']),
        FactoryGirl.build(:contributor, contributor_name: ['Contributor 3'],
                                        affiliation: ['Affiliation 3'],
                                        role: ['http://id.loc.gov/vocabulary/relators/edt'],
                                        order: ['3'])
      ] }
    end

  end
end
