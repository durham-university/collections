require 'nokogiri'
require 'httparty'

namespace :data_cite do

	desc "DataCite batch ingest metadata of given DOI. Example use rake data_cite:ingest_doi[44558D349,dch1sp,EPSRC,2015-09-16\ 61:12\ UTC]"
	task :ingest_doi, [:id,:depositor,:funder,:date_created] => :environment do |t, args|
		args.with_defaults(depositor: 'dch1sp',
						   funder: 'Engineering and Physical Sciences Research Council', 
						   date_created: Time.new )

		map = Datacite.get_data(args.id)
		if map[:funder].empty? 
			map[:funder] = [args.funder]
		end
		map[:date_created] = [args.date_created]
		puts map

		Collection.ingest_doi(args.id,map,args.depositor )
	end

	desc "DataCite batch ingest of all existing DOIs metadata. It will use default /opt/sufia/confing.yml file. Different file location can be set rake data:cite[/new/file/location/existing_dois.yml]"
	task :all, [:dois_file] => :environment do |t, args|
		args.with_defaults(dois_file: '/opt/sufia/config/existing_dois.yml',
						   depositor: 'dch1sp')

		if File.exists?(args.dois_file)
			DOIS = YAML.load_file(args.dois_file)
			DOIS.each do |id, date_created|
				puts "Processing DOI:10.15128/#{id} created at #{date_created}"

				map = Datacite.get_data(id)
				if map[:funder].empty? 
					map[:funder]=['Engineering and Physical Sciences Research Council']
				end
				map[:date_created] = [date_created]
				puts map

				Collection.ingest_doi(id,map,args.depositor)
			end
		else
			puts "Non existing file #{args.dois_file}"
		end
	end

	desc "Allocate IDs for requested DOIs"
	task :allocate, [:dois_file] => :environment do |t, args|
		args.with_defaults(dois_file: '/opt/sufia/config/allocated_dois.yml',
						   depositor: 'dch1sp')

		if File.exists?(args.dois_file)
			DOIS = YAML.load_file(args.dois_file)
			DOIS.keys.each do |id|
				date = Time.parse(DOIS[id]['date'])
				name = DOIS[id]['name']
				puts "Allocate ID for DOI:10.15128/#{id} requested #{date}"

				map = {
				      title: "This is holding tile for requested DOI:10.15128/#{id}",
				      tag: ['place holder'],
				      contributors_attributes: [
				      	{contributor_name: [name],
				      	affiliation: ['Durham University, UK'], 
						role: ['http://id.loc.gov/vocabulary/relators/cre'],
						order: [0]},
						{contributor_name: [name], 
						affiliation: ['Durham University, UK'], 
						role: ['http://id.loc.gov/vocabulary/relators/mdc'],
						order: [1]}],
				      funder: ['Engineering and Physical Sciences Research Council'],
				      date_created: [date] #Add real date from spreadsheet 
				    }
				    puts map

				    Collection.ingest_doi(id,map,args.depositor)
			end
		else
			puts "Non existing file #{args.dois_file}"
		end
	end	

end
