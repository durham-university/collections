module HydraDurham
  module PropertyWithRelevance
    extend ActiveSupport::Concern

    class ValueWithRelevance < ActiveTriples::Resource
      include NestedResource
      configure type: ::RDF::URI.new('http://collections.durham.ac.uk/ns#value_with_relevance_wrapper')
      property :value, predicate: ::RDF::URI.new('http://collections.durham.ac.uk/ns#value_with_relevance_wrapped_value')
      property :relevance, predicate: ::RDF::URI.new('http://collections.durham.ac.uk/ns#value_with_relevance_wrapped_relevance')
    end

    included do
      class << self
        attr_accessor :properties_with_relevance
      end
      self.properties_with_relevance = []

      def initialize(*args)
        super(*args)
        @json_properties_with_relevance=nil
      end

      def init_with_json(*args)
        @json_properties_with_relevance={}
        super(*args)
      end

      def as_json(*args)
        super(*args).tap do |json|
          self.class.properties_with_relevance.each do |prop|
            json[prop.to_s] = json[prop.to_s].map(&:as_json)
          end
        end
      end

      def adapt_attributes(attrs,*rest)
        self.class.properties_with_relevance.each do |prop|
          @json_properties_with_relevance[prop] = attrs[prop.to_s].map do |hash|
            ValueWithRelevance.new(hash['id'],nil).tap do |v| v.init_with_json(hash) end
          end
        end
        return super(attrs.except(*self.class.properties_with_relevance),*rest)
      end

      def get_values(*args)
        return super(*args) unless @json_properties_with_relevance && self.class.properties_with_relevance.include?(args.first)
        return @json_properties_with_relevance[args.first]
      end
    end

    module ClassMethods
      def property_with_relevance(name, options, &block)
        raise ArgumentError, "PropertyWithRelevance can only be used with multi-value properties" unless options.fetch(:multiple, true)
        raise ArgumentError, "PropertyWithRelevance does not support reject_if" if options.key?(:reject_if)

        wrapper_predicate = options.fetch(:wrapper_predicate, "#{options[:predicate]}_with_relevance")
        wrapper_name = options.fetch(:wrapper_name, "#{name}_with_relevance").to_sym

        self.properties_with_relevance << wrapper_name

        property wrapper_name, options.except( :wrapper_predicate, :wrapper_name ).merge({
          predicate: wrapper_predicate,
          class_name: HydraDurham::PropertyWithRelevance::ValueWithRelevance
        })

        self.class_eval <<-CODE, __FILE__, __LINE__ + 1
          def #{name}(*args)
            wrapped_value = #{wrapper_name}(*args)
            sorted_value = (wrapped_value.to_a.sort do |a,b| b.relevance.first <=> a.relevance.first end).map do |x| x.value.first end
            sorted_value
          end
        CODE

        self.class_eval <<-CODE, __FILE__, __LINE__ + 1
          def #{name}=(value)
            self.#{wrapper_name} = []
            value.to_a.each_with_index do |v,i|
              #{wrapper_name}.build(value: [v], relevance: [1.0/(i+1)])
            end
          end
        CODE

        send(:add_attribute_indexing_config, name, &block) if block_given?
      end
    end
  end
end
