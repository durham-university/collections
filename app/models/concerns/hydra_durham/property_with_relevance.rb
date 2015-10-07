module HydraDurham
  module PropertyWithRelevance
    extend ActiveSupport::Concern

    class ValueWithRelevance < ActiveTriples::Resource
      configure type: ::RDF::URI.new('http://collections.durham.ac.uk/ns#value_with_relevance_wrapper')
      property :value, predicate: ::RDF::URI.new('http://collections.durham.ac.uk/ns#value_with_relevance_wrapped_value')
      property :relevance, predicate: ::RDF::URI.new('http://collections.durham.ac.uk/ns#value_with_relevance_wrapped_relevance')

      def initialize(uri,parent)
        if uri.try(:node?)
          uri = RDF::URI("#nested_#{uri.to_s.gsub('_:','')}")
        elsif uri.start_with?("#")
          uri = RDF::URI(uri)
        end
        super
      end
      def final_parent
        parent
      end
    end

    module ClassMethods
      def property_with_relevance(name, options, &block)
        raise ArgumentError, "PropertyWithRelevance can only be used with multi-value properties" unless options.fetch(:multiple, true)
        raise ArgumentError, "PropertyWithRelevance does not support reject_if" if options.key?(:reject_if)

        wrapper_predicate = options.fetch(:wrapper_predicate, "#{options[:predicate]}_with_relevance")
        wrapper_name = options.fetch(:wrapper_name, "#{name}_with_relevance").to_sym

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
