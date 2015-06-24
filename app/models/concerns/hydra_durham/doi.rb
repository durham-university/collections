module HydraDurham
  module Doi
    extend ActiveSupport::Concern

    # Returns all doi identifiers in the resource.
    def doi
      identifier.select do |ident|
  			(/doi:/i =~ ident || /info:doi/i =~ ident || /dx.doi.org/i =~ ident)
      end
    end

    # Add the reserved doi identifier into the resource identifier list.
    # Does not save the resource or mint the doi.
    def add_doi
      if not has_local_doi?
        identifier << full_mock_doi
      end
    end

    # Returns true if the resource has any doi identifier, one reserved by
    # this application or an outside one.
    def has_doi?
      not doi.empty?
    end

    # Returns true if the resource has a doi reserved by this application.
    def has_local_doi?
      not not ( identifier.index full_mock_doi )
    end

    # Returns true if the management of the resource in Datacite is our
    # responsibility
    def manage_datacite?
      has_local_doi?
    end

    # Returns the reserved doi the resource would be assigned by this application,
    # whether or not it has been already assigned. Does not include the "doi:"
    # uri scheme.
    def mock_doi
      "#{DOI_CONFIG['doi_prefix']}/#{id}"
    end

    # Returns the reserved doi the resource would be assigned by this application,
    # whether or not it has been already assigned. Does include the "doi:" uri scheme.
    def full_mock_doi
      "doi:#{mock_doi}"
    end

    # Returns the landing page to be used for the resource.
    def doi_landing_page
      # is there a way to get this somehow with url_for or some such?
      url = DOI_CONFIG['landing_page_prefix']
      if self.class == Collection
  			url + "collections/" + id
  		else
  			url + "files/" + id
  		end
    end

    # Gets the resource Datacite metadata as XML.
    def doi_metadata_xml
      DataciteXml.new.generate(doi_metadata)
    end

    # Makes sure that the object has all the metadata required by Datacite.
    # Returns an array with information of any missing matadata. Empty array
    # indicates that no problems were detected.
    def validate_doi_metadata
      ret = []

      ret << "The resource must have an author" if authors.empty?
      ret << "The resource must have a resource type" if resource_type.empty?
      ret << "The resource must have a title" if title.empty?

      return ret
    end

    def member_visible? m
      m.visibility=='open'
    end

    # Gets the resource Datacite metadata as a hash.
    def doi_metadata
      # This must be mock_doi rather than any identifier defined in the object.
      # Otherwise users could manually specify a different identifier and
      # change records they're not supposed to.
      data = {:identifier => mock_doi}

      if respond_to? :doi_published and doi_published
        data[:publication_year] = "#{doi_published.year}"
      else
        data[:publication_year] = "#{Time.new.year}"
      end

      data[:subject] =
        (subject.to_a.map do |e|
          { scheme:'FAST', schemeURI: 'http://fast.oclc.org/', label: e }
        end) +
        (tag.to_a.map do |e|
          { scheme: nil, schemeURI: nil, label: e}
        end)

      # TODO: When we have roles in authors, use actual creators here
      #       and put others in contributors with the right contributorType.
      #       Also make sure validation makes sure that authors has a creator.
      data[:creator] = authors.map do |c|
        { name: c.author_name.first,
          affiliation: c.affiliation.first
        }
      end

      data[:abstract] = abstract.to_a
      data[:research_methods] = research_methods.to_a
      data[:funder] = funder.to_a
      data[:contributor] = []

      data[:relatedIdentifier] = related_url.map do |url|
        # related field is now titled cited by, so use that as the relation type
        {id: url, id_type: 'URL', relation_type: 'IsCitedBy'}
      end

  		if self.class == GenericFile
  			data[:title] = title
        data[:description] = description.to_a
        data[:resource_type] = resource_type.first # Only maping first choice from the list
        data[:size] = [content.size]
  			data[:format] = [content.mime_type]
  			data[:date_uploaded] = date_uploaded.strftime('%Y-%m-%d')
        data[:rights] = rights.map do |frights|
  				{rights: Sufia.config.cc_licenses_reverse[frights], rightsURI: frights}
  			end
  		else #Add Collection metadata
  			data[:title] = [title] # Collection returns string, XML builder expects array
        data[:description] = ( description.empty? ? [] : [description] )
  			# FixMe: construct << {contributor, email}
        if not date_created.empty?
          data[:date_created] = Date.parse(date_created.first.to_s).strftime('%Y-%m-%d') unless date_created.empty?
        end
        data[:resource_type] = 'Collection'

  			#Add members metadata
  			data[:rights] = rights.map do |crights|
  				{rights: "Collection rights - " + Sufia.config.cc_licenses_reverse[crights], rightsURI: crights }
  			end
        members.reduce(data[:rights]) do |a,mobj|
          if member_visible? mobj
            if mobj.content.original_name.nil? then filename = mobj.id else filename = mobj.content.original_name end
            a << { # Do we allow for multiple licensing?
              rights: filename + " - " + Sufia.config.cc_licenses_reverse[mobj.rights[0]],
              rightsURI: mobj.rights[0]
            }
          else
            a
          end
  			end

        data[:format] = members.reduce([]) do |a,mobj|
          if member_visible? mobj
            if mobj.content.original_name.nil? then filename = mobj.id else filename = mobj.content.original_name end
            if mobj.content.mime_type.nil? then a end
            a << (filename + " - " + mobj.content.mime_type)
          else
            a
          end
  			end

        data[:size] = members.reduce([]) do |a,mobj|
          if member_visible? mobj
            if mobj.content.original_name.nil? then filename = mobj.id else filename = mobj.content.original_name end
            if mobj.content.size then a end
            a << "#{filename} - #{mobj.content.size}"# Should we preatyfier file size in bytes?
          else
            a
          end
  			end


        members.reduce(data[:relatedIdentifier]) do |a,mobj|
          if member_visible? mobj and mobj.respond_to? :doi_landing_page #FixMe: only public objects
            a << { id: mobj.doi_landing_page, id_type: 'URL', relation_type: 'HasPart' }
          else
            a
          end
  			end
  		end
      return data
    end
  end
end
