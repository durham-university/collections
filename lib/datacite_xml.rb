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
              # if c.key?(:affiliation)
                # xml.affiliation c[:affiliation]
              # else
                # xml.affiliation affiliation
              # end
            }
          end
        }

        xml.titles {
          map[:title].each do |t|
            xml.title t
          end
        }

        xml.publisher "Durham University"

        xml.publicationYear map[:publication_year]


        xml.subjects {
          map[:subject].each do |s|
            xml.subject s
          end
        }

        xml.dates {
          if map.has_key?(:date_uploaded) then xml.date map[:date_uploaded], :dateType=>'Submitted' end
          if map.has_key?(:date_ceated) then xml.date map[:date_created], :dateType=>'Created' end 
        }

        xml.resourceType Sufia.config.resource_types_to_datacite[map[:resource_type]], :resourceTypeGeneral=>Sufia.config.resource_types_to_datacite_reverse[map[:resource_type]]

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
            map[:relatedIdentifier].each do |rid|
              xml.relatedIdentifier "http://collections.durham.ac.uk/files/"+rid, :relatedIdentifierType=>"URL", :relationType=>"HasPart"
            end 
          }
        end

        if map[:description].any?
          xml.descriptions{
            map[:description].each do |d|
              xml.description d, :descriptionType=>'Other'
            end
          }
        end

      }
    end
    return builder.to_xml  
  end
end