# Note, this file almost identical to DurhamRails::ArkBehaviour
module HydraDurham
  module ArkBehaviour
    extend ActiveSupport::Concern

    included do
      before_create :assign_new_ark
    end

    def assign_id
      id_from_ark || super
    end

    def ark_identifier_property
      :identifier
    end

    def assign_new_ark
      if ark_naan && local_ark.nil?
        @minted_ark_id = "ark:/#{ark_naan}/#{service.mint}"
        # this is essentially just   identifier += [ark_id]
        self.send(:"#{ark_identifier_property}=", self.send(ark_identifier_property) + [@minted_ark_id])
      end
    end

    def local_ark
      return nil unless ark_naan
      prefix = "ark:/#{ark_naan}/"
      self.send(ark_identifier_property).select do |ident| ident.start_with?(prefix) end .sort.first
    end

    def id_from_ark
      # Only make a fedora id from ark if we just minted the ark. Otherwise
      # we might use some manually assigned ark as a fedora id which could cause
      # various issues.
      return nil unless ark_naan && @minted_ark_id
      prefix = "ark:/#{ark_naan}/"
      @minted_ark_id[(prefix.length)..-1]
    end

    def ark_naan
      self.class.ark_naan
    end

    module ClassMethods
      def ark_naan
        @ark_naan ||= DURHAM_CONFIG['ark_naan']
      end
    end
  end
end
