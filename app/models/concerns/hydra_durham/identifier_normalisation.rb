module HydraDurham
  module IdentifierNormalisation
    extend ActiveSupport::Concern

    included do
      before_save :normalise_record_identifiers!
      before_save :normalise_record_related_url!
    end

    # Note that DOI has some identifier logic as well. The normalised identifiers
    # must be compatible with DOI identifier rules. As long as DOI rules recognise
    # all the prefixes used here things should work fine.
    IDENTIFIER_RULES = [
        'doi',
        {regex: /^info:doi\/(.*)/i, value: 'doi:\1' },
        {regex: /^.*dx\.doi\.org\/(.*)/i, value: 'doi:\1' },
        'arxiv',
        {regex: /^.*arxiv\.org\/[^\/]+\/(.*)/i, value: 'arxiv:\1'},
        'issn', 'isbn', 'istc', 'lissn',
        'urn:lsid:', 'pmid', 'purl',
        {regex: /(.*([\W]|^)purl\W.*)/i, value: 'purl:\1'},
        'upc', 'urn' # urn should be second to last because LSID also starts with urn
      ]

    IDENTIFIER_URL_RULES = [
      { prefix: 'doi', value: 'http://dx.doi.org/\1' },
      { prefix: 'arxiv', value: 'http://arxiv.org/abs/\1' },
      { prefix: 'http', value: 'http:\1' },
      { prefix: 'https', value: 'https:\1' }
    ]

    def normalise_record_identifiers!
      self.identifier = self.identifier.to_a.map do |ident|
        self.class.normalise_identifier(ident)
      end
    end

    def normalise_record_related_url!
      return unless self.respond_to?(:related_url)
      self.related_url = self.related_url.to_a.map do |ident|
        self.class.normalise_identifier(ident)
      end
    end

    module ClassMethods
      def normalise_identifier ident
        IDENTIFIER_RULES.each do |rule|
          if rule.class==String
            rule={ prefix: "#{rule.downcase}:" }
          end
          if rule.key? :regex
            if rule[:regex] =~ ident
              return ident.sub(rule[:regex], rule[:value])
            end
          else
            if ident.downcase.start_with?(rule[:prefix])
              return ident[0..(rule[:prefix].length-1)].downcase+ident[(rule[:prefix].length)..-1]
            end
          end
        end
        return ident
      end

      def identifier_link ident
        IDENTIFIER_URL_RULES.each do |rule|
          if ident.start_with? rule[:prefix]
            return ident.sub(Regexp.new("#{rule[:prefix]}:(.*)"),rule[:value])
          end
        end
        return nil
      end
    end

  end
end
