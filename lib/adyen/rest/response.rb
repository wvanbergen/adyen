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
    # @!attribute options [r]
    #   An options hash that is used to interpret the response.
    #   @return [Hash]
    #
    # @see Adyen::REST::Client
    # @see Adyen::REST::Request
    class Response
      attr_reader :http_response, :options

      def initialize(http_response, options = {})
        @http_response, @options = http_response, options
      end

      # The prefix that every response attribute names should have.
      #
      # The prefix is set by setting the <tt>:prefix</tt> key in the
      # {#options} hash.
      # @return [String, nil] Returns the response attribute prefix, if any.
      def prefix
        @prefix ||= options[:prefix].to_s
      end

      # Returns the attributes of the response as a nested hash.
      #
      # The HTTP response contains all attributes as a flatten dictionary.
      # This method constructs a nested structure, and converts all the keys
      # to underscore notation.
      #
      # @return [Hash] The nested hash of response attributes
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

      # Looks up an attribute in the response.
      # @return [String, nil] The value of the attribute if it was included in the response.
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
