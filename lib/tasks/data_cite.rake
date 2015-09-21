require 'nokogiri'
require 'httparty'

namespace :data_cite do

	# Fetch DOI metadata from DataCite XML file 
	def get_data(doi)
		url = 'http://data.datacite.org/application/x-datacite+xml/10.15128/'+doi
		response = HTTParty.get(url)

		xml = Nokogiri::XML( response.body )
		xml.remove_namespaces!
		resource = xml % "resource"

		# if resource % 'identifier'
		# 	puts 'Processing DOI: '+((resource/'identifier').first.attributes['identifierType']).to_s+':'+(resource % 'identifier').inner_html
		# end

		creators_map = {}
		creators = resource.xpath("//resource/creators/creator")
		if creators.count != 0
			for i in 0..creators.count-1
				creators_map[i]=[creators[i].xpath('creatorName').inner_html,creators[i].xpath('affiliation').inner_html]
			end
		end

		titles_a = []
		titles = resource.xpath("//resource/titles/title")
		if titles.count != 0
			for i in 0..titles.count-1
				if titles[i]['titleType'] != nil
					titles_a[i] = titles[i].inner_html
				else
					titles_a[i] = titles[i].inner_html
				end	
			end
		end

		contributors_map = {}
		contributors = resource.xpath("//resource/contributors/contributor[@contributorType='ContactPerson']")
		if contributors.count != 0
			for i in 0..contributors.count-1
				if creators[i].xpath('affiliation').count != 0
					affiliation = contributors[i].xpath('affiliation').inner_html
				else
					affiliation = "Durham University, UK"
				end
				contributors_map[i]=[contributors[i].xpath('contributorName').inner_html,affiliation]
			end
		end

		subject_a = []
		subjects = resource.xpath("//resource/subjects/subject")
		if subjects.count != 0
			for i in 0..subjects.count-1
				if subjects[i]['subjectScheme'] != nil
					subject_a[i] = subjects[i].inner_html
				else
					subject_a[i] = subjects[i].inner_html
				end	
			end
		end

		relatedIdentifiers_a =[]
		relatedIdentifiers = resource.xpath("./relatedIdentifiers/relatedIdentifier")
		if relatedIdentifiers.count != 0
			for i in 0..relatedIdentifiers.count-1
				if relatedIdentifiers[i]['relationType'] != nil
						relatedIdentifiers_a[i]=relatedIdentifiers[i].inner_html
				end	
			end
		end

		descriptions_map = {}
		descriptions_a = resource.xpath("//resource/descriptions/description[@descriptionType='Abstract']")
		if !descriptions_a.empty?
				descriptions_map[:abstract] = descriptions_a.inner_html
		end
		descriptions_o = resource.xpath("//resource/descriptions/description[@descriptionType='Other']")
		if !descriptions_o.empty?
				descriptions_map[:other] = descriptions_o.inner_html
		end
		descriptions_m = resource.xpath("//resource/descriptions/description[@descriptionType='Methods']")
		if !descriptions_m.empty?
				descriptions_map[:methods] = descriptions_m.inner_html
		end

		return {
					:creators => creators_map,
					:titles => titles_a, 
					:subjects => subject_a,
					:contributors => contributors_map, 
					:relatedIdentifiers => relatedIdentifiers_a,
					:descriptions => descriptions_map
				}
	end

	desc "DataCite batch ingest metadata of given DOI. Example use rake data_cite:ingest_doi[44558D349,2015-09-16\ 61:12\ UTC]"
	task :ingest_doi, [:id,:date_created] => :environment do |t, args|
		args.with_defaults(date_created: Time.new )

		begin 
			c = Collection.new(id:args.id.to_s.downcase)
		rescue ActiveFedora::IllegalOperation => e
			puts "Object #{args.id} #{args.date_created} already exists"
			next
		end

		map = get_data(args.id)
		puts map

		# # Create object with existing DOI status will fail
		# c.identifier = ["doi:#{DOI_CONFIG['doi_prefix']}/#{args.id.to_s.downcase}"]
		# c.doi_published = Date.parse(args.date_created)
		# # Validation failed: 
		# # 	Title cannot be changed when DOI has been published, 
		# # 	Contributors cannot be changed when DOI has been published
		# c.datacite_document = map.to_json

		c.resource_type = ['Collection']
		c.title = map[:titles][0]
		c.abstract = [map[:descriptions][:abstract]] if map[:descriptions][:abstract].present?		
		c.description = [map[:descriptions][:other]] if map[:descriptions][:other].present?
		c.research_methods = [map[:descriptions][:methods]] if map[:descriptions][:methods].present?
		c.funder = ['Engineering and Physical Sciences Research Council']
		c.tag = map[:subjects]
		# # c.subject = ['subject1', 'subject2']
		c.related_url = map[:relatedIdentifiers] if map[:relatedIdentifiers].present?
		# c.date_uploaded = DateTime.parse('Thu, 16 Jul 2015 12:44:38 +0100')
		#puts c.to_json

		for i in 0..map[:creators].count-1
			c.contributors.new(contributor_name: [map[:creators][i][0]], 
						  affiliation: [map[:creators][i][1]], 
						  role: ['http://id.loc.gov/vocabulary/relators/cre'],
						  order: [i])
		end
		for i in 0..map[:contributors].count-1
			c.contributors.new(contributor_name: [map[:contributors][i][0]], 
						  affiliation: [map[:contributors][i][1]], 
						  role: ['http://id.loc.gov/vocabulary/relators/mdc'],
						  order: [i])
		end

		c.depositor="dch1sp"
		c.edit_users=["dch1sp"]
		c.save!

		puts c.to_solr
	end

	desc "DataCite batch ingest of all existing DOIs metadata. It will use default /opt/sufia/confing.yml file. Different file location can be set rake data:cite[/new/file/location/existing_dois.yml]"
	task :all, [:dois_file] => :environment do |t, args|
		args.with_defaults(dois_file: '/opt/sufia/config/existing_dois.yml')

		if File.exists?(args.dois_file)
			DOIS = YAML.load_file(args.dois_file)
			DOIS.each do |id, date_created|
				puts "Processing DOI:10.15128/#{id} created at #{date_created}"
				Rake::Task["data_cite:ingest_doi"].invoke(id, date_created)
				Rake::Task["data_cite:ingest_doi"].reenable
			end
		else
			puts "Non existing file #{args.dois_file}"
		end
	end

	desc "Allocate IDs for requested DOIs"
	task :allocate, [:dois_file] => :environment do |t, args|
		args.with_defaults(dois_file: '/opt/sufia/config/allocated_dois.yml')

		if File.exists?(args.dois_file)
			DOIS = YAML.load_file(args.dois_file)
			DOIS.each do |id, creator|
				puts "Allocate ID for DOI:10.15128/#{id}"

				begin 
					c = Collection.new(id:id.to_s.downcase)
				rescue ActiveFedora::IllegalOperation => e
					puts "Object #{args.id} #{args.date_created} already exists"
					next
				end

				c.resource_type = ['Collection']
				c.title = "This is holding tile for requested DOI:10.15128/#{id}"
				c.funder = ['Engineering and Physical Sciences Research Council']
				c.tag = [' ']
				puts c
				puts "Creator: #{creator}"

				c.contributors.new(contributor_name: [creator], 
								  affiliation: ['Durham University, UK'], 
								  role: ['http://id.loc.gov/vocabulary/relators/cre'],
								  order: [0])
				
				c.contributors.new(contributor_name: [creator], 
								  affiliation: ['Durham University, UK'], 
								  role: ['http://id.loc.gov/vocabulary/relators/mdc'],
								  order: [0])

				c.depositor="dch1sp"
				c.edit_users=["dch1sp"]
				c.save!

				puts c.to_solr				
			end
		else
			puts "Non existing file #{args.dois_file}"
		end
	end	

end
