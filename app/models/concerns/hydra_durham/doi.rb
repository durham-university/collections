module HydraDurham
  module Doi
    extend ActiveSupport::Concern

    included do
      property :doi_published, predicate: ::RDF::URI.new('http://collections.durham.ac.uk/ns#doi_published'), multiple: false do |index|
        index.type :date
        index.as :stored_searchable
      end

      # This is a JSON serialised version of the document sent to DataCite.
      property :datacite_document, predicate: ::RDF::URI.new('http://collections.durham.ac.uk/ns#datacite_document'), multiple: false

      attr_accessor :skip_update_datacite

      validate :validate_doi_and_datacite_fields

      after_save { update_datacite_metadata unless @skip_update_datacite }
      after_destroy { update_datacite_destroyed unless @skip_update_datacite }
    end

    def update_datacite_metadata
      queue_doi_metadata_update depositor
    end

    def update_datacite_destroyed
      queue_doi_metadata_update depositor, destroyed: true
    end

    # perform model level validation before saving
    def validate_doi_and_datacite_fields
      errors.add(:doi_published, "can't be changed after set once") \
          if !changed_attributes["doi_published"].nil? &&
              changed_attributes["doi_published"]!=doi_published

      errors.add(:identifier, "can't have local DOI removed after set once") \
          if changed_attributes["identifier"] &&
             (changed_attributes["identifier"].index full_mock_doi) &&
             !(identifier.index full_mock_doi)

      if !manage_datacite? # i.e. no local doi identifier set
        errors.add(:doi_published, "can't be set if not managing datacite") \
            if !doi_published.nil?
        errors.add(:datacite_document, "can't be set if not managing datacite") \
            if !datacite_document.nil?
      else
        errors.add(:doi_published, "must be set when managing datacite") \
            if doi_published.nil?
        errors.add(:datacite_document, "must be set when managing datacite") \
            if datacite_document.nil?

        if !datacite_document.nil?
          old_doc=JSON.parse datacite_document
          # cycling serialisation makes sure that keys are strings instead of symbols
          new_doc=JSON.parse(doi_metadata.to_json)

          restricted_mandatory_datacite_fields.each do |field|
            errors.add(field[:source], "cannot be changed when DOI has been published") \
                if old_doc[field[:dest].to_s]!=new_doc[field[:dest].to_s]
          end

        end
      end

    end

    # Checks if an edit field should be disabled due to the resource having a
    # published DOI and the field is one of the restricted fields. Also checks
    # For a local doi in the identifier field.
    def field_readonly?(field,value=nil)
      # Some other behaviours might want to use field_readonly as well.
      # Try to play nice and call super if it's defined and there's no need
      # to disable the field due to DOIs.
      ret= if manage_datacite? && \
              ((restricted_mandatory_datacite_fields.map do |x| x[:source] end) \
                .include? field)
        true
      else
        (field==:identifier && value==full_mock_doi)
      end
      return ret if ret || !defined?(super)
      super
    end

    # Fields that cannot be changed after a DOI has been published.
    # The source is the field name in our model, dest in the datacite model.
    def restricted_mandatory_datacite_fields
      # Publisher is not here because it is hardcoded in datacite_xml.rb.
      # Publication year is also managed internally.
      [ { source: :title, dest: :title},
        { source: :contributors, dest: :creator } ]
    end


    # Queues a metadata update job
    def queue_doi_metadata_update(user, mint: false, destroyed: false, force: false)
      raise "Cannot mint and destroy DOI at the same time" if mint && destroyed
      if destroyed && manage_datacite?
        # TODO: object was destroyed, send something to DataCite
      elsif (manage_datacite? || mint) && (datacite_metadata_changed? || force)
        Sufia.queue.push(UpdateDataciteJob.new(self.id, user, do_mint: mint))
      end

      # Update all dependent items.
      dependent_doi_items.each do |collection|
        collection.queue_doi_metadata_update collection.depositor
      end
    end

    # Gets all items that are managed in DataCite and that depend on this item.
    def dependent_doi_items
      # if this resource isn't open access or isn't collectible then just return an empty list
      return [] if (!respond_to? :collections) || visibility!=Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC
      # return all collections this is part of that are managed in DataCite
      collections.to_a.select do |collection|
        (collection.respond_to? :doi) && collection.manage_datacite?
      end
    end

    # Checks if the given identifier is a doi identifier
    def doi_identifier? ident
      (/doi:/i =~ ident || /info:doi/i =~ ident || /dx.doi.org/i =~ ident)
    end

    # Returns all doi identifiers in the resource.
    def doi
      identifier.select do |ident|
        doi_identifier? ident
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

    # Returns true if the resource, or the given id collection, has a doi
    # reserved by this application.
    def has_local_doi? ids=nil
      ids||=identifier
      not not ( ids.index full_mock_doi )
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

    # Checks if metadata that would be sent to datacite has changed since the
    # last time it was updated. The last sent metadata is stored in datacite_document
    # and newly generated metadata is compared to that. If you have the metadata
    # generated by doi_metadata already, you can give that as the first argument
    # to save generating it again. Always returns true if datacite_document is nil.
    def datacite_metadata_changed? metadata=nil
      return true if datacite_document.nil?
      metadata||=doi_metadata
      metadata=JSON.parse(metadata.to_json) if metadata.key? :title
      old_metadata=JSON.parse(datacite_document)
      return metadata!=old_metadata
    end

    # Gets the resource Datacite metadata as XML.
    def doi_metadata_xml metadata=nil
      metadata||=doi_metadata
      DataciteXml.new.generate(metadata)
    end

    # Makes sure that the object has all the metadata required by Datacite.
    # Returns an array with information of any missing matadata. Empty array
    # indicates that no problems were detected.
    def validate_doi_metadata
      ret = []

      # Restrict to single values of various fields because we can't guarantee the
      # ordering and choosing the first one might choose different one each time

      ret << "The resource must have a contributor" if contributors.empty?
      ret << "The resource must have a resource type" if resource_type.empty?
      ret << "The resource can only have a single resource_type" if (resource_type.is_a? Array) && resource_type.length>1
      ret << "The resource must have a title" if title.empty?
      ret << "The resource can only have a single title" if (title.is_a? Array) && title.length>1

      ret << "Contributors can only have a single name and affiliation" if \
        (contributors.to_a.select do |c|
          c.contributor_name.length>1 || c.affiliation.length>1
        end).any?

      return ret
    end

    def member_visible? m
      m.visibility=='open'
    end

    # Guesses the type of the identifier based on its contents. Returns
    # The a hash containing the type and the identifier possibly reformatted.
    def guess_identifier_type ident

      rules=[{regex: /^doi:(.*)/i, type: 'DOI', value: '\1' },
             {regex: /^info:doi\/(.*)/i, type: 'DOI', value: '\1' },
             {regex: /^.*dx\.doi\.org\/(.*)/i, type: 'DOI', value: '\1' },
             {regex: /^arxiv:(.*)/i, type: 'arXiv', value: 'arXiv:\1'},
             {regex: /^.*arxiv\.org\/[^\/]+\/(.*)/i, type: 'arXiv', value: 'arXiv:\1'},
             'issn', 'isbn', 'istc', 'lissn',
             {prefix: 'urn:lsid:', type: 'LSID', keep_prefix: true}, 'pmid',
             {regex: /^purl:(.*)/i, type: 'PURL', value: '\1'},
             {regex: /(.*([\W]|^)purl\W.*)/i, type: 'PURL', value: '\1'},
             'upc',
             {prefix: 'urn', type: 'URN', keep_prefix: true},  # urn should be second to last because LSID also starts with urn
             {regex: /(.*)/, type: 'URL', value: '\1'} ]

      rules.each do |rule|
        if rule.class==String
          rule={ prefix: "#{rule}:", type: rule.upcase }
        end
        if rule.key? :regex
          if rule[:regex] =~ ident
            return { id_type: rule[:type], id: (ident.sub rule[:regex], rule[:value])}
          end
        else
          if ident.downcase.start_with?(rule[:prefix])
            if rule[:keep_prefix]
              return { id_type: rule[:type], id: ident }
            else
              return { id_type: rule[:type], id: ident[(rule[:prefix].length) .. -1]}
            end
          end
        end
      end

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

      # TODO: When we have roles in contributors, use actual creators here
      #       and put others in contributors with the right contributorType.
      #       Also make sure validation makes sure that contributors has a creator.
      data[:creator] = (contributors.to_a.select do |c|
        !c.marked_for_destruction?
      end).map do |c|
        { name: c.contributor_name.first,
          affiliation: c.affiliation.first
        }
      end

      data[:abstract] = abstract.to_a
      data[:research_methods] = research_methods.to_a
      data[:funder] = funder.to_a
      data[:contributor] = []

      data[:relatedIdentifier] = related_url.map do |url|
        # related field is now titled cited by, so use that as the relation type
        (guess_identifier_type url).tap do |ident| ident[:relation_type]='IsCitedBy' end
      end

      if self.class == GenericFile
        data[:title] = title
        data[:description] = description.to_a
        data[:resource_type] = Sufia.config.resource_types_to_datacite[resource_type.first] # Only maping first choice from the list
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
        data[:resource_type] = Sufia.config.resource_types_to_datacite['Collection']

        #Add members metadata
        data[:rights] = rights.map do |crights|
          {rights: "Collection rights - " + Sufia.config.cc_licenses_reverse[crights], rightsURI: crights }
        end
        members.reduce(data[:rights]) do |a,mobj|
          if member_visible? mobj
            if mobj.content.original_name.nil? then filename = mobj.id else filename = mobj.content.original_name end
            if mobj.rights.any?
              a << { # Do we allow for multiple licensing?
                rights: filename + " - " + Sufia.config.cc_licenses_reverse[mobj.rights[0]],
                rightsURI: mobj.rights[0]
              }
            else
              a
            end
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
