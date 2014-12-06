module Adyen
  module REST
    class Response
      attr_reader :attribute_prefix, :http_response

      def initialize(attribute_prefix, http_response)
        @attribute_prefix, @http_response = attribute_prefix.to_s, http_response
      end

      def attributes
        @attributes ||= begin
          prefixed_attributes = parse_response_attributes
          if Set.new(prefixed_attributes.keys) != Set[attribute_prefix]
            raise "Unexpected response attribute_prefixes: #{prefixed_attributes.keys.join(', ')}"
          end

          prefixed_attributes[attribute_prefix]
        end
      end

      def [](key)
        attributes[key.to_s]
      end

      def has_attribute?(key)
        attributes.key?(key.to_s)
      end

      def psp_reference
        Integer(attributes['psp_reference'])
      end

      def result_code
        attributes['result_code']
      end

      protected

      def parse_response_attributes
        attributes = CGI.parse(http_response.body)
        attributes.each { |key, values| attributes[key] = values.first }
        Adyen::Util.deflatten(attributes)
      end
    end
  end
end
