module Adyen
  module REST

    # The Response class models the HTTP response that is the result of a
    # API call to Adyen's REST webservice.
    #
    # Some API calls may respond with an instance of a subclass, to make
    # dealing with the response easier.
    #
    # @!attribute http_response [r]
    #   The underlying net/http response.
    #   @return [Net::HTTPResponse]
    # @!attribute prefix [r]
    #   The prefix to use when reading attributes from the response
    #   @return [String]
    #
    # @see Adyen::REST::Client
    # @see Adyen::REST::Request
    class Response
      attr_reader :http_response, :prefix, :attributes

      def initialize(http_response, options = {})
        @http_response = http_response
        @prefix = options.key?(:prefix) ? options[:prefix].to_s : nil
        @attributes = parse_response_attributes
      end

      # Looks up an attribute in the response.
      # @return [String, nil] The value of the attribute if it was included in the response.
      def [](name)
        attributes[canonical_name(name)]
      end

      def has_attribute?(name)
        attributes.has_key?(canonical_name(name))
      end

      def psp_reference
        Integer(self[:psp_reference])
      end

      protected

      def map_response_list(response_prefix, mapped_attributes)
        list  = []
        index = 0

        loop do
          response = {}
          mapped_attributes.each do |key, value|
            new_value = attributes["#{response_prefix}.#{index.to_s}.#{value}"]
            response[key] = new_value unless new_value.empty?
          end

          index += 1
          break unless response.any?
          list << response
        end

        list
      end

      def canonical_name(name)
        Adyen::Util.camelize(apply_prefix(name))
      end

      def apply_prefix(name)
        prefix ? name.to_s.sub(/\A(?!#{Regexp.quote(prefix)}\.)/, "#{prefix}.") : name.to_s
      end

      def parse_response_attributes
        attributes = CGI.parse(http_response.body)
        attributes.each { |key, values| attributes[key] = values.first }
        attributes
      end
    end
  end
end
