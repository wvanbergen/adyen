require 'adyen/util'
require 'adyen/rest/errors'
require 'adyen/rest/response'

module Adyen
  module REST

    # The request object models an API request to be sent to Adyen's webservice.
    #
    # Some API calls may use a subclass to model their request.
    #
    # @!attribute prefix [r]
    #   The prefix to use for every request attribute (except action)
    #   @return [String]
    # @!attribute form_data [r]
    #   The attributes to include in the API request as form data.
    #   @return [Hash<String, String>] A dictionary of key value pairs
    # @!required_attributes [r]
    #   The list of required attributes that should show up in the request.
    #   {#validate!} will fail if any of these attributes is missing or empty.
    #   @return [Array<String>]
    # @!attribute response_class [rw]
    #   The response class to use to wrap the HTTP response to this request.
    #   @return [Class]
    # @!attribute response_options [rw]
    #   The options to send to the response class initializer.
    #   @return [Hash]
    #
    # @see Adyen::REST::Client
    # @see Adyen::REST::Response
    class Request
      attr_reader :prefix, :form_data, :required_attributes, :path
      attr_accessor :response_class, :response_options

      def initialize(action, attributes, options = {})
        @form_data = generate_form_data(attributes)
        @path = generate_path(action)

        @response_class   = options[:response_class]   || Adyen::REST::Response
        @response_options = options[:response_options] || {}

        @required_attributes = []
      end

      # Returns the request's action
      # @return [String]
      def action
        form_data['action']
      end

      # Retrieves an attribute from the request
      def [](attribute)
        form_data[canonical_name(attribute)]
      end

      # Sets an attribute on the request
      def []=(attribute, value)
        form_data.merge!(Adyen::Util.flatten(attribute => value))
        value
      end

      def merchant_account=(value)
        self[:merchant_account] = value
      end

      # Runs validations on the request before it is sent.
      # @return [void]
      # @raises [Adyen::REST::RequestValidationFailed]
      def validate!
        required_attributes.each do |attribute|
          if form_data[attribute].nil? || form_data[attribute].empty?
            raise Adyen::REST::RequestValidationFailed, "#{attribute} is empty, but required!"
          end
        end
      end

      # Builds a Adyen::REST::Response instnace for a given Net::HTTP response.
      # @param http_response [Net::HTTPResponse] The HTTP response return for this request.
      # @return [Adyen::REST::Response] An instance of {Adyen::REST::Response}, or a subclass.
      def build_response(http_response)
        response_class.new(http_response, response_options)
      end

      protected

      def canonical_name(name)
        Adyen::Util.camelize(name)
      end

      # @return [Hash<String, String>] A dictionary of API request attributes that
      def generate_form_data(attributes)
        Adyen::Util.flatten(attributes)
      end

      def generate_path(action)
        PATH % action.split('.')
      end

      # @see Adyen::REST::Request#set_path
      PATH = '/pal/servlet/%s/v12/%s'
      private_constant :PATH
    end
  end
end
