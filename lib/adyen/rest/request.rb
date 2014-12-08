module Adyen
  module REST

    # The request object models an API request to be sent to Adyen's webservice.
    #
    # Some API calls may use a subclass to model their request.
    #
    # @!attribute action [r]
    #   The API action to request
    #   @return [String]
    # @!attribute attributes [r]
    #   The attributes to include in the API request.
    #   @return [Hash] A nested hash. The leaf nodes should be strings.
    # @!attribute options
    #   Options hash for this API request.
    #   @return [Hash]
    #
    # @see Adyen::REST::Client
    # @see Adyen::REST::Response
    class Request
      attr_reader :action, :prefix, :attributes
      attr_accessor :response_class, :response_options

      def initialize(action, attributes, options = {})
        @action, @attributes = action, attributes

        @prefix           = options.key?(:prefix) ? options[:prefix].to_s : nil
        @response_class   = options[:response_class]   || Adyen::REST::Response
        @response_options = options[:response_options] || {}
      end

      # Runs validations on the request before it is sent.
      # @return [void]
      # @raises [Adyen::REST::RequestError]
      def validate!
      end

      # Flattens the {#attributes} hash and converts all the keys to camelcase.
      # @return [Hash<String, String>] A dictionary of API request attributes that
      #   can be included in an HTTP request as form data.
      def flattened_attributes
        if prefix
          Adyen::Util.flatten(prefix => attributes, :action => action)
        else
          Adyen::Util.flatten(attributes.merge(:action => action))
        end
      end

      # Builds a Adyen::REST::Response instnace for a given Net::HTTP response.
      # @param http_response [Net::HTTPResponse] The HTTP response return for this request.
      # @return [Adyen::REST::Response] An instance of {Adyen::REST::Response}, or a subclass.
      def build_response(http_response)
        response_class.new(http_response, response_options)
      end
    end
  end
end
