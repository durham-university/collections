class DoiController < ApplicationController
 	def show
	   	@id = params[:id]
	   	@resource = ActiveFedora::Base.find(@id)
		@doi = "10.15128/#{@id}"
		@has_doi = false
		@identifier = @resource.identifier
		@identifiers = @resource.identifier.each { |ident|
			if (/doi:/ =~ ident ||
				/info:doi/ =~ ident ||
				/dx.doi.org/ =~ ident)
				@has_doi = ident
			end
		}  
	end

	def update
		#This will be minting test/production DOI
		@id = params[:id]
	   	@resource = ActiveFedora::Base.find(@id)
		@doi = DoiHelper.mock(@id)
		@xml = DoiHelper.metadata(@id)
		@url = DoiHelper.landing_page(@id)

		datacite = Datacite.new
		datacite.metadata(@xml)
		datacite.mint(@url,@doi)

		#fobj.identifier = ["DOI:#{@doi}"]
		# fobj.date = Time.new.year
		# fobj.save
	end
end
