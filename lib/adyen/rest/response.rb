module Adyen
  module REST
    class Response
      attr_reader :http_response, :options

      def initialize(http_response, options = {})
        @http_response, @options = http_response, options
      end

      def prefix
        @prefix ||= options[:prefix].to_s
      end

      def attributes
        @attributes ||= begin
          prefixed_attributes = parse_response_attributes
          if prefix
            if Set.new(prefixed_attributes.keys) != Set[prefix]
              raise "Unexpected response attribute_prefixes: #{prefixed_attributes.keys.join(', ')}"
            end

            prefixed_attributes[prefix]
          else
            prefixed_attributes
          end
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
