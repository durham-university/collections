module HydraDurham
  module FedoraBigFieldGuard
    extend ActiveSupport::Concern
    
    class FieldTooBigError < StandardError
    end
    
    FEDORA_MAX_SIZE = 4096
    
    included do
      before_save :fedora_big_field_guard
    end
    
    private
    
      def fedora_big_field_guard
        self.class.properties.keys.each do |prop|
          Array.wrap(self[prop]).each do |val|
            if val.to_s.bytes.length >= FEDORA_MAX_SIZE
              raise FieldTooBigError, "#{prop} value is too big. Fedora cannot handle values bigger than #{FEDORA_MAX_SIZE}" 
            end
          end
        end
      end
  end
end