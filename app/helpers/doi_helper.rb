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
			@data[:description] = fobj.description
			@data[:size] = fobj.file_size
			@data[:relatedIdentifier] = [] # empty array to avoid issue wtih nil.any?
			@data[:format] = [fobj.format_label[0] + " - " + fobj.mime_type] # xml builder expects array here
			@data[:date_uploaded] = Date.parse(fobj.date_uploaded.to_s).strftime('%Y-%m-%d')
			rights = [{ # Do we allow for multiple licensing?
						rights: fobj.filename[0] + " - " + Sufia.config.cc_licenses_reverse[fobj.rights[0]],
						rightsURI: fobj.rights[0] }]
			@data[:rights] = rights

		else #Add Collection metadata
			
			@data[:title] = [fobj.title] # Collection returns string, XML builder expects array
			@data[:description] = [fobj.description]
			@data[:date_created] = Date.parse(fobj.date_created.to_s).strftime('%Y-%m-%d')

			#Add members metadata
			rights = Array[{rights: "Collection rights - " + Sufia.config.cc_licenses_reverse[fobj.rights[0]], rightsURI: fobj.rights[0] }]
			fobj.member_ids.each do |mid|
				mobj = ActiveFedora::Base.find(mid)
				rights << { # Do we allow for multiple licensing?
							rights: mobj.filename[0] + " - " + Sufia.config.cc_licenses_reverse[mobj.rights[0]],
							rightsURI: mobj.rights[0] 
						}
			end
			@data[:rights] = rights 

			format = Array.new
			fobj.member_ids.each do |mid|
				mobj = ActiveFedora::Base.find(mid)
				format << mobj.filename[0] + " - " + mobj.mime_type 
			end
			@data[:format] = format 
			
			size = Array.new
			fobj.member_ids.each do |mid|
				mobj = ActiveFedora::Base.find(mid)
				size << mobj.filename[0] + " - " + mobj.file_size[0] # Should we preatyfier file size in bytes?
			end
			@data[:size] = size 

			relatedIdentifier = Array.new
			fobj.member_ids.each do |mid|
				mobj = ActiveFedora::Base.find(mid)
				relatedIdentifier << mobj.id # all will be mapped to default HasPart URI 
			end
			@data[:relatedIdentifier] = relatedIdentifier 
		end
		DataciteXml.new.generate(@data)
	end	

end