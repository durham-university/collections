module DoiHelper
	def save_resource 
		i = @resource.identifier
		i << "doi:" + @doi
		@resource.identifier = i
		@resource.save!
	end

	def self.prefix
		# Determine prefix test/live 
		if Rails.env.production? then
			return "10.15128"
		else
			return "10.4124"
		end
	end

	def identifier? id
		#Check if object has live DOI - perheps Fedora should have identifier with prefix
		length = GenericFile.find(id).identifier.length
		if length == 0 then
			return "false"
		else
			return "true"
		end
	end

	def self.mock id
		@doi = prefix + "/" + id
	end

	def self.landing_page id
		url = "http://collections.durham.ac.uk"

		if @resource.class == Collection
			landin_page = url + "/collections/" + id
		else
			landin_page = url + "/files/" + id
		end
	end

	# Crosswalk Fedora/Sufia data to DataCite
	def self.metadata id
		fobj =  ActiveFedora::Base.find(id)
		
		@data = {:identifier => mock(id)}
		@data[:publication_year] = Time.new.year
		@data[:subject] = fobj.tag
		@data[:resource_type] = fobj.resource_type[0] # Only maping first choice from the list
		creator = Array.new
		fobj.creator.each do |c|
			creator << {:name => c} 
		end
		@data[:creator] = creator		

		if fobj.class == GenericFile

			@data[:title] = fobj.title

			description = Array.new
			fobj.description.each do |fdesc|
				description << fdesc
			end
			@data[:description] = description 
			
			abstract = Array.new
			fobj.abstract.each do |fabstract|
				abstract << fabstract
			end 
			@data[:abstract] = abstract

			research_methods = Array.new
			fobj.research_methods.each do |method|
				research_methods << method
			end
			@data[:research_methods] = research_methods

			funder = Array.new
			fobj.resarch_methods.each do |fun|
				funder << fun
			end
			@data[:funder] = funder

			@data[:size] = fobj.file_size
			size = Array.new
			size << fobj.content.size
			@data[:size] = size
			relatedIdentifier = Array.new
			fobj.related_url.each do |url|
				relatedIdentifier << url
			end
			@data[:relatedIdentifier] = relatedIdentifier
			format = Array.new
			# fobj.format_label.each do |flable|
			# 	format << flabel + " - " + fobj.mime_type
			# end
			format << fobj.content.mime_type
			@data[:format] = format
			@data[:date_uploaded] = Date.parse(fobj.date_uploaded.to_s).strftime('%Y-%m-%d')
			rights = Array.new
			fobj.rights.each do |frights|
				rights << {rights: Sufia.config.cc_licenses_reverse[frights], rightsURI: frights}
			end
			@data[:rights] = rights

		else #Add Collection metadata
			
			@data[:title] = [fobj.title] # Collection returns string, XML builder expects array

			if ! fobj.description.empty? then
				@data[:description] = [fobj.description] # Collection only singular currently 
			end

			abstract = Array.new
			fobj.abstract.each do |fabstract|
				abstract << fabstract
			end 
			@data[:abstract] = abstract
			
			research_methods = Array.new
			fobj.research_methods.each do |method|
				research_methods << method
			end
			@data[:research_methods] = research_methods

			funder = Array.new
			fobj.funder.each do |fun|
				funder << fun
			end
			@data[:funder] = funder

			contributor = Array.new
			# FixMe: construct << {contributor, email} 
			@data[:contributor] = contributor

			if ! fobj.date_created[0].nil? then
				@data[:date_created] = Date.parse(fobj.date_created.to_s).strftime('%Y-%m-%d')
			end
			
			#Add members metadata
			rights = Array.new
			fobj.rights.each do |crights|
				rights << {rights: "Collection rights - " + Sufia.config.cc_licenses_reverse[crights], rightsURI: crights }
			end
			fobj.member_ids.each do |mid|
				mobj = ActiveFedora::Base.find(mid)
				if mobj.content.original_name.nil? then filename = mobj.id else filename = mobj.content.original_name end
				rights << { # Do we allow for multiple licensing?
							rights: filename + " - " + Sufia.config.cc_licenses_reverse[mobj.rights[0]],
							rightsURI: mobj.rights[0] 
						}
			end
			@data[:rights] = rights 

			format = Array.new
			fobj.member_ids.each do |mid|
				mobj = ActiveFedora::Base.find(mid)
				if mobj.content.original_name.nil? then filename = mobj.id else filename = mobj.content.original_name end
				if mobj.content.mime_type.nil? then next end
				format << filename + " - " + mobj.content.mime_type 
			end
			@data[:format] = format 
			
			size = Array.new
			fobj.member_ids.each do |mid|
				mobj = ActiveFedora::Base.find(mid)
				if mobj.content.original_name.nil? then filename = mobj.id else filename = mobj.content.original_name end
				if mobj.content.size then next end
				size << filename + " - " + mobj.content.size # Should we preatyfier file size in bytes?
			end
			@data[:size] = size

			relatedIdentifier = Array.new
			fobj.related_url.each do |url|
				relatedIdentifier << url
			end
			fobj.member_ids.each do |mid|
				mobj = ActiveFedora::Base.find(mid)
				relatedIdentifier << "http://collections.durham.ac.uk/files/" + mobj.id # all will be mapped to default HasPart URI 
			end
			@data[:relatedIdentifier] = relatedIdentifier 
		end
		DataciteXml.new.generate(@data)
	end	

end