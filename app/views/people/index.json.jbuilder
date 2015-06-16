json.array!(@people) do |person|
  json.extract! person, :id, :full_name, :orcid, :cis_username, :affiliation
  json.url person_url(person, format: :json)
end
