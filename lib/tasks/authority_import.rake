require 'open-uri'
require 'zip'

namespace :authority_import do
  def download_file(url,dest)
    File.open(dest,'wb') do |out_file|
      open(url) do |in_file|
        out_file.write(in_file.read)
      end
    end
  end

  desc "Downloads the needed RDF files"
  task :download_all => [:download_languages, :download_funders] do
  end

  desc "Downloads the language rdf"
  task :download_languages, [:force_download] do |t, args|
    args.with_defaults( force_download: false,
                        languages_file: Rails.root.join('tmp','iso6392.rdf') )

    file=args.languages_file
    if args.force_download or not File.exists?(file)
      tempFile=Rails.root.join('tmp','languages-import-download.zip')
      puts "Downloading compressed languages rdf to #{tempFile}"
      download_file('http://id.loc.gov/static/data/vocabularyiso639-2.rdfxml.zip',tempFile)
      begin
        found=false
        Zip::File.open(tempFile) do |zip_file|
          zip_file.each do |entry|
            if entry.name=='iso6392.rdf'
              puts "Extracting languages rdf to #{file}"
              entry.extract(file)
              found=true
            end
          end
        end
        raise "Couldn't find the rdf inside the ZIP file" if not found
      ensure
        rm tempFile
      end
    else
      puts "Using existing languages file #{file}."
    end
  end

  desc "Downloads the funders rdf"
  task :download_funders, [:force_download] do |t, args|
    args.with_defaults( force_download: false,
                        funders_file: Rails.root.join('tmp','fundref_registry.rdf') )

    file=args.funders_file
    if args.force_download or not File.exists?(file)
      puts "Downloading funders rdf to #{file}"
      download_file('http://data.fundref.org/fundref/registry',file)
    else
      puts "Using existing funders file #{file}."
    end
  end

  desc "Imports funders RDF registry. Download the RDF from http://www.crossref.org/fundref/fundref_registry.html. The RDF file name should be given as a parameter or be in the same directory."
  task :funders, [:funders_file,:funders_authority_name] => [:download_funders, :environment] do |t, args|
    args.with_defaults( funders_file: Rails.root.join('tmp','fundref_registry.rdf'),
                        funders_authority_name: 'la_fundref_registry' )

    file=args.funders_file
    la_name=args.funders_authority_name

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
      puts "Loading funders RDF data from #{file}"
      puts "Importing to local authority #{la_name}"
      LocalAuthority.harvest_rdf_sparql(la_name, file, query, append: false)

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
  task :languages, [:languages_file,:languages_authority_name] => [:download_languages, :environment] do |t, args|
    args.with_defaults( languages_file: Rails.root.join('tmp','iso6392.rdf'),
                        languages_authority_name: 'la_languages_iso6392')
    file=args.languages_file
    la_name=args.languages_authority_name

    la=LocalAuthority.find_by(name: la_name)
    if not la
      query=
        'PREFIX mads: <http://www.loc.gov/mads/rdf/v1#> '\
        'SELECT ?term ?label ?altLabel '\
        'WHERE { '\
        '  { '\
        '    <http://id.loc.gov/vocabulary/iso639-2/collection_iso639-2_Bibliographic_Codes> mads:hasMADSCollectionMember ?term .'\
        '    ?term mads:authoritativeLabel ?label .'\
        '    FILTER ( lang(?label) = "en" ) '\
        '  } UNION { '\
        '    <http://id.loc.gov/vocabulary/iso639-2/collection_iso639-2_Bibliographic_Codes> mads:hasMADSCollectionMember ?term .'\
        '    ?term mads:authoritativeLabel ?label .'\
        '    FILTER ( lang(?label) = "en" ) .'\
        '    ?term mads:hasVariant ?variant .'\
        '    ?variant mads:variantLabel ?altLabel .'\
        '    FILTER ( lang(?altLabel) = "en" ) .'\
        '    FILTER ( ?altLabel != ?label ) .'\
        '  } '\
        '}';
      puts "Loading languages RDF data from #{file}"
      puts "Importing to local authority #{la_name}"
      LocalAuthority.harvest_rdf_sparql(la_name, file, query, append: false) do |r|
        a = {term: r[:term], altLabel: r[:altLabel],
          label: r[:label].to_s.split(/\s*\|\s*/)[0] }
        (a[:label].to_s != a[:altLabel].to_s) ? a : nil
      end

      puts "Associating domain terms of collections and generic_files with #{la_name}"
      la=LocalAuthority.find_by(name: la_name)
      collections_dt=DomainTerm.find_or_create_by(model: 'collections', term: 'language')
      collections_dt.local_authorities << la
      collections_dt.save

      files_dt=DomainTerm.find_or_create_by(model: 'generic_files', term: 'language')
      files_dt.local_authorities << la
      files_dt.save
      puts "Done importing languages"
    else
      puts "Local authority #{la_name} already exists. Stopping."
    end

  end

  task all: [:funders, :languages] do
  end
end
