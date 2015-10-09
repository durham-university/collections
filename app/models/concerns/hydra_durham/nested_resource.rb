module HydraDurham
  module NestedResource
    extend ActiveSupport::Concern

    def initialize(uri,parent)
      if uri.try(:node?)
        uri = RDF::URI("#nested_#{uri.to_s.gsub('_:','')}")
      elsif uri.start_with?("#")
        uri = RDF::URI(uri)
      end
      @json_values=nil
      super
    end
    def final_parent
      parent
    end

    def as_json(*args)
      super(*args).slice('id',*(self.class.properties.keys))
    end

    def init_with_json(json) # parsed JSON, not string
      @json_values=json.each_with_object({}) do |(k,v),o| o[k.to_sym]=v end
    end

    def get_values(*args)
      return super(*args) unless @json_values
      return @json_values[args.first]
    end
  end
end
