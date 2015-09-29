require 'nokogiri'
require 'httparty'


namespace :data_cite do
  def ingest_doi(id,depositor,funder,date_created=nil)
    map = Datacite.get_data(id)
    map[:funder] = [funder] if map[:funder].empty?
    map[:date_created] = [date_created || DateTime.now]
    puts map

    GenericFile.ingest_doi(id,map,depositor)
  end

  desc "Ingest metadata of a given DOI."
  task :ingest_doi, [:id,:depositor,:funder,:date_created] => :environment do |t, args|
    args.with_defaults(depositor: 'dch1sp',
               funder: 'Engineering and Physical Sciences Research Council' )
    date_created = nil
    date_created = DateTime.parse(args.date_created) if args.date_created
    ingest_doi(args.id, args.depositor, args.funder, date_created )
  end

  desc "DataCite batch ingest of all existing DOIs metadata."
  task :existing_dois, [:depositor,:existing_dois_file,:funder] => :environment do |t, args|
    args.with_defaults(existing_dois_file: 'config/existing_dois.yml',
                 depositor: 'dch1sp',
                funder: 'Engineering and Physical Sciences Research Council' )

    if File.exists?(args.existing_dois_file)
      DOIS = YAML.load_file(args.existing_dois_file)
      DOIS.each do |id, date_created|
        puts "Processing DOI:#{DOI_CONFIG['fetch_doi_prefix']}/#{id} created at #{date_created}"
        ingest_doi(id, args.depositor, args.funder, DateTime.parse(date_created) )
      end
    else
      puts "Non existing file #{args.dois_file}"
    end
  end

  desc "Allocate IDs for requested DOIs"
  task :allocated_dois, [:depositor,:allocated_dois_file,:funder] => :environment do |t, args|
    args.with_defaults(allocated_dois_file: 'config/allocated_dois.yml',
                 depositor: 'dch1sp',
                funder: 'Engineering and Physical Sciences Research Council' )

    if File.exists?(args.allocated_dois_file)
      DOIS = YAML.load_file(args.allocated_dois_file)
      DOIS.each do |id, hash|
        name = hash['name']
        date = DateTime.parse(hash['date'])
        puts "Allocate ID for #{DOI_CONFIG['fetch_doi_prefix']}/#{id} requested #{date}"

        map = {
              title: ["This is holding tile for requested #{DOI_CONFIG['fetch_doi_prefix']}/#{id}"],
              tag: [],
              contributors_attributes: [
                {
                  contributor_name: [name],
                  affiliation: ['Durham University, UK'],
                  role: ['http://id.loc.gov/vocabulary/relators/cre'],
                  order: [0]
                },
                {
                  contributor_name: [name],
                  affiliation: ['Durham University, UK'],
                  role: ['http://id.loc.gov/vocabulary/relators/mdc'],
                  order: [1]
                }
              ],
              funder: [args.funder],
              date_created: [date] #Add real date from spreadsheet
            }
        puts map

        GenericFile.ingest_doi(id,map,args.depositor)
      end
    else
      puts "Non existing file #{args.dois_file}"
    end
  end


  desc "Allocate IDs for requested DOIs and ingest existing DOIs"
  task :ingest_all, [:depositor,:existing_dois_file,:allocated_dois_file,:funder] => [:allocated_dois, :existing_dois] do
  end

end
