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
      attr_accessor :action, :attributes, :options

      def initialize(action, attributes, options = {})
        @action, @attributes, @options = action, attributes, options
      end

      # Runs validations on the request before it is sent.
      # @return [void]
      # @raises [Adyen::REST::RequestError]
      def validate!
      end

      # The prefix to use for all attributes in this request.
      #
      # The prefix is set by setting the <tt>:prefix</tt> key in the
      # {#options} hash.
      # @return [String, nil] Returns the request attribute prefix, if any.
      def prefix
        @prefix ||= options[:prefix].to_s
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
    end
  end
end
