require 'nokogiri'

NS = {
  "xmlns" => "http://datacite.org/schema/kernel-3",
  "xmlns:xsi" => "http://www.w3.org/2001/XMLSchema-instance",
  "xsi:schemaLocation" => "http://datacite.org/schema/kernel-3 http://schema.datacite.org/meta/kernel-3/metadata.xsd"
}

class DataciteXml

  # generate DataCite XML with metadata
  def generate(map)

    # affiliation = "Durham University"
    builder = Nokogiri::XML::Builder.new(:encoding => 'UTF-8') do |xml|
      xml.resource (NS) {

        xml.identifier map[:identifier], :identifierType=>'DOI'

        xml.creators {
          map[:creator].each do |c|
            xml.creator {
              xml.creatorName c[:name]
               if c.key?(:affiliation) and c[:affiliation].present?
                 xml.affiliation c[:affiliation]
               end
            }
          end
        }

        xml.titles {
          map[:title].each do |t|
            xml.title t
          end
        }

        xml.publisher DOI_CONFIG['datacite_publisher']

        xml.publicationYear map[:publication_year]

        xml.contributors {
          xml.contributor(:contributorType=>'RightsHolder') {
            xml.contributorName DOI_CONFIG['datacite_contributor']
          }
          xml.contributor(:contributorType=>'HostingInstitution') {
            xml.contributorName DOI_CONFIG['datacite_hosting_institution']
          }
          if map[:funder].any? then
            map[:funder].each do |f|
              xml.contributor(:contributorType=>'Funder') {
                xml.contributorName f
                # xml.contributorName "Engineering and Physical Sciences Research Council (EPSRC)
                # xml.nameIdentifier :nameIdentifierScheme=>'FundRef', schemeURI=>'http://www.crossref.org/fundref">http://dx.doi.org/10.13039/501100000266'
              }
            end
          end
          if map[:contributor].any? then
            map[:contributor].each do |f|
              xml.contributor(:contributorType=>'ContactPerson') {
                xml.contributorName f
                # xml.nameIdentifier :nameIdentifierScheme=>'URI mailto', schemeURI=>'<mailto:upload.name@durham.ac.uk>'
              }
            end
          end
        }

        xml.subjects {
          map[:subject].each do |s|
            attrs={}
            attrs[:subjectScheme] = s[:scheme] if s.key? :scheme and s[:scheme]
            attrs[:schemeURI] = s[:schemeURI] if s.key? :schemeURI and s[:schemeURI]
            xml.subject s[:label], attrs
          end
        }

        xml.dates {
          if map.has_key?(:date_uploaded) then xml.date map[:date_uploaded], :dateType=>'Submitted' end
          if map.has_key?(:date_created) then xml.date map[:date_created], :dateType=>'Created' end
        }

        xml.resourceType Sufia.config.resource_types_to_datacite[map[:resource_type]], :resourceTypeGeneral=>Sufia.config.resource_types_to_datacite[map[:resource_type]]

        if map[:size].any?
          xml.sizes {
            map[:size].each do |s|
            xml.size s
          end
          }
        end

        if map[:format].any?
          xml.formats {
            map[:format].each do |f|
              xml.format f
            end
          }
        end

        if map[:rights].any?
          xml.rightsList {
            map[:rights].each do |r|
              xml.rights r[:rights], :rightsURI=>r[:rightsURI]
            end
          }
        end

        if map[:relatedIdentifier].any?
          xml.relatedIdentifiers {
            map[:relatedIdentifier].each do |rel|
              xml.relatedIdentifier rel[:id],
                  :relatedIdentifierType=>rel[:id_type],
                  :relationType=>rel[:relation_type]
            end
          }
        end

        if map[:description].any? or map[:abstract].any? or map[:research_methods].any?
          xml.descriptions {
            if map[:description].any?
              map[:description].each do |d|
                xml.description d, :descriptionType=>'Other'
              end
            end
            if map[:abstract].any?
              map[:abstract].each do |d|
                xml.description d, :descriptionType=>'Abstract'
              end
            end
            if map[:research_methods].any?
              map[:research_methods].each do |d|
                xml.description d, :descriptionType=>'Methods'
              end
            end
          }
        end

      }
    end
    return builder.to_xml
  end
end
