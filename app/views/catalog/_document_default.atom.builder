xml.entry do

  xml.title presenter(document).render_document_index_label(document_show_link_field(document))
  
  # set updated time depending on what sort option is used
  update_time = if params[:sort].try(:start_with?,'doi published') && document.to_model.respond_to?(:doi_published)
    document.to_model.doi_published
  elsif params[:sort].try(:start_with?,'system_create')
    document.to_model.date_uploaded
  elsif params[:sort].try(:start_with?,'system_modified')
    document.to_model.date_modified
  else
    document.to_model.date_uploaded 
  end
  xml.updated((update_time || Time.current).iso8601)
  
  xml.link    "type" => "text/html", "href" => polymorphic_url(url_for_document(document))
  # add other doc-specific formats, atom only lets us have one per
  # content type, so the first one in the list wins.
  # xml << render_link_rel_alternates(document, :unique => true)      
  
  xml.id polymorphic_url(url_for_document(document))
  
  
#  if document.to_semantic_values.key? :author
#    xml.author { xml.name(document.to_semantic_values[:author].first) }
#  end
  
  if document.hydra_model == 'GenericFile'
    xml.summary  do
      xml.text! document.to_model.export_as_apa_citation
    end
  end
end
