# FASTResource uses assignFAST (http://experimental.worldcat.org/fast/assignfast/)
# for controlled vocabulary suggestions. Used primarily in AuthoritiesController.
# Most of the code is just working around and overriding ActiveResource::Base
# behaviour to suit our needs.

class FASTResource < ActiveResource::Base
  self.site = "http://fast.oclc.org/searchfast"
  self.element_name = "fastsuggest"
  self.collection_name = "fastsuggest"

  def self.collection_path(prefix_options = {}, query_options = nil)
    # ActiveResource::Base insists on adding .json or .xml in the url, get rid of it
    super(prefix_options, query_options).gsub(/\.json|\.xml/, "")
  end

  def self.instantiate_collection(collection, original_params = {}, prefix_options = {})
    # restructure the response into the expected format
    query_index=original_params[:queryIndex]
    col = super(collection['response']['docs'], original_params, prefix_options)
    col.map! { |item|
      # Auth is the authoritative term, entry is the term that matched the search.
      # If these two are different then it means that you should use the auth term
      # in place of what the user searched for.
      auth=item.auth
      entry=item.attributes[query_index][0]
      {
        label: entry,
        value: auth,
        note: (auth==entry) ? nil : "Use #{auth}"
      }
    }
  end

  def self.find_suggestions(query,query_index)
    return FASTResource.find(:all, params: { query: query, queryIndex: query_index, queryReturn: "#{query_index},auth,id", suggest: 'autoSubject', rows: 10 })
  end
end
