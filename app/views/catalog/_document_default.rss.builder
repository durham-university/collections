xml.item do  
  xml.title(presenter(document).render_document_index_label(document_show_link_field(document)) || (document.to_semantic_values[:title].first if document.to_semantic_values.key?(:title)))
  xml.link(polymorphic_url(url_for_document(document)))

  if document.hydra_model == 'GenericFile'
    xml.description do
      xml.text! document.to_model.export_as_apa_citation
    end
  end
  
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
  xml.pubDate( (update_time || Time.current).iso8601 )
end