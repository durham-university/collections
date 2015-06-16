# Base class for creating authority classes that get terms from Solr.
# See names_solr_authority for an example and instructions on how to
# use this.

class SolrAuthorityBase
  include Blacklight::SearchHelper
  include Blacklight::Configurable

  # these define which fields are used in the search and how
  # results are processed
  class_attribute :solr_fq_map
  class_attribute :solr_fl
  class_attribute :solr_translate_map
  class_attribute :solr_query_fields

  def initialize()
  end

  # builds the filter query based on solr_fq_map
  def self.build_fq
    fq=''
    self.solr_fq_map.each do |k,v|
      if not fq.empty? then fq+=' AND ' end
      fq+="#{k}:#{v}"
    end
    return fq
  end

  # builds the field list based on solr_fl_map
  def self.build_fl
    self.solr_fl.join ' '
  end

  # Builds one part of the Solr query. The parameter here should be
  # a single term, that is no white space in it.
  def build_q_part(s)
    q=''
    solr_query_fields.each do |f|
      if not q.empty? then q+=' OR ' end
      q+="#{f}:#{s}*"
    end
    return q
  end

  # cleans user supplied query string
  def clean_query(s)
    s.strip
     .slice(0,50) # don't process ridiculously long queries
     .gsub(/[^\w\s]/, ' ') # Substitute all non-alphanumeric characters just to
                           # be safe. Could probably let some others through but
                           # need to check if this causes vulnerabilities in solr.

  end

  # Builds the actual Solr query. The query is split at white space and
  # each term is processed separately with build_q_part. The parts are
  # joined with the AND operand.
  def build_q(s)
    s=clean_query(s)
    q=''
    # split query into parts, and process at most five of them
    s.split(/\s+/).slice(0,5).each do |ss|
      if not ss.empty?
        if not q.empty? then q+=' AND ' end
        qp=build_q_part(ss)
        q+="(#{qp})"
      end
    end
    return q
  end

  # Translates results from solr into the final hash. Works based on
  # solr_fl_map
  def translate_results(list)
    list.map { |d|
      res={}
      solr_translate_map.each do |k,v|
        if v.is_a? Proc
          v.call(res,d,k)
        else
          res[v]=d[k].first
        end
      end
      res
    }
  end

  # Inits Blacklight. Must be called by subclasses after setting the solr
  # class variables.
  def self.init_blacklight
    copy_blacklight_config_from CatalogController

    configure_blacklight do |conf|
      # conf.search_builder_class = LocalNameSearchBuilder
      conf.default_solr_params = {
        fq: self.build_fq,
        fl: self.build_fl,
        rows: 10
      }
    end
  end

  # Main entry for the authority. Performs the lookup and returns a list of
  # found terms.
  def search(q)
    q=build_q(q)
    if q.empty?
      # don't perform empty queries
      return []
    end
    _, list = search_results({q: q }, [
        :default_solr_parameters,
        :add_query_to_solr])
    translate_results(list)
  end

end
