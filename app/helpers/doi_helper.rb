module DoiHelper
	def save_resource 
		i = @resource.identifier
		i << "doi:" + @doi
		@resource.identifier = i
		@resource.save!
	end
end