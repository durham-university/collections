# Name authority using Solr lookups
class NamesSolrAuthority < SolrAuthorityBase
  # Filter query, restrict to people
  self.solr_fq_map={
    has_model_ssim: 'Person'
  }

  self.solr_fl=['full_name_tesim','affiliation_tesim']

  # Maps results from Solr to a hash by changing field names and possibly
  # doing other processing
  self.solr_translate_map={
    # simple map from Solr field full_name_tesim to a field id
    full_name_tesim: 'value',
    # pass a Proc for custom processing.
    label: Proc.new do |result,solr,key|
      affiliation=solr[:affiliation_tesim]
      if affiliation and !affiliation.empty?
        affiliation=" (#{affiliation.first})"
      else
        affiliation=''
      end
      result['label']="#{solr[:full_name_tesim].first}#{affiliation}"
    end
  }

  # Search in these Solr fields
  self.solr_query_fields=['full_name_tesim','cis_username_tesim','orcid_tesim']

  # Must call this after all the class variables have been set
  self.init_blacklight
end
