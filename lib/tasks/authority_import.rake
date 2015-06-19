namespace :authority_import do
  desc "Imports funders RDF registry. Download the RDF from http://www.crossref.org/fundref/fundref_registry.html. The RDF file name should be given as a parameter or be in the same directory."
  task :funders, [:file,:authority_name] => :environment do |t, args|
    args.with_defaults( file: 'fundref_registry.rdf',
                        authority_name: 'la_fundref_registry' )

    la_name=args.authority_name

    la=LocalAuthority.find_by(name: la_name)
    if not la
      query=
        'PREFIX skosxl: <http://www.w3.org/2008/05/skos-xl#> '\
        'SELECT ?term ?label ?altLabel '\
        'WHERE { '\
        '  { '\
        '    ?term skosxl:prefLabel ?x .'\
        '    ?x skosxl:literalForm ?label .'\
        '  } UNION { '\
        '    ?term skosxl:prefLabel ?x .'\
        '    ?x skosxl:literalForm ?label .'\
        '    ?term skosxl:altLabel ?y .'\
        '    ?y skosxl:literalForm ?altLabel .'\
        '  } '\
        '}';
      puts "Loading funders RDF data from #{args.file}"
      puts "Importing to local authority #{la_name}"
      LocalAuthority.harvest_rdf_sparql(la_name, args.file, query, append: false)

      puts "Associating domain terms of collections and generic_files with #{la_name}"
      la=LocalAuthority.find_by(name: la_name)
      collections_dt=DomainTerm.find_or_create_by(model: 'collections', term: 'funder')
      collections_dt.local_authorities << la
      collections_dt.save

      files_dt=DomainTerm.find_or_create_by(model: 'generic_files', term: 'funder')
      files_dt.local_authorities << la
      files_dt.save
      puts "Done importing funders"
    else
      puts "Local authority #{la_name} already exists. Stopping."
    end
  end

  desc "Imports languages RDF registry. Download the RDF from http://id.loc.gov/static/data/vocabularyiso639-2.rdfxml.zip. The RDF file name should be given as a parameter or be in the same directory."
  task :languages, [:file] => :environment do |t, args|
    puts "Languagse import not yet implemented"
    args.with_defaults( file: 'iso6392.rdf',
                        authority_name: 'la_languages_iso6392')
  end

  task all: [:funders, :languages] do
  end
end
