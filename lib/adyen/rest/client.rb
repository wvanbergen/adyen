require 'cgi'
require 'net/http'

require 'adyen/rest/errors'
require 'adyen/rest/request'
require 'adyen/rest/response'
require 'adyen/rest/authorise_payment'

module Adyen
  module REST

    # The Client class acts as a client to Adyen's REST webservice.
    #
    # @!attribute environment [r]
    #   The adyen environment to interact with. Either <tt>'live'</tt> or <tt>'test'</tt>.
    #   @return [String]
    class Client
      include AuthorisePayment

      attr_reader :environment

      # @param environment [String] The Adyen environment to interface with. Either
      #   <tt>'live'</tt> or <tt>'test'</tt>.
      # @param username [String] The webservice username, e.g. <tt>ws@Company.Account</tt>
      # @param password [String] The password associated with the username
      def initialize(environment, username, password)
        @environment, @username, @password = environment, username, password
      end

      # Closes the client.
      #
      # - This will terminate the HTTP connection.
      # - After calling this method, the behavior of any further method calls against
      #   this client instance is undefined.
      #
      # @return [void]
      def close
        @http.finish if @http && @http.started?
        @http = nil
      end

      # The underlying <tt>Net::HTTP</tt> instance that is used to execute HTTP
      # request against the API.
      #
      # You can use this to set options on the Net::HTTP instance, like <tt>read_timeout</tt>.
      # Many of these options will only work if you set them before the HTTP connection is
      # opened, i.e. before doing the first API call.
      #
      # @return [Net::HTTP] The underlying Net::HTTP instance the client uses to perform HTTP request.
      def http
        @http ||= Net::HTTP.new(endpoint.host, endpoint.port).tap do |http|
          http.use_ssl = endpoint.scheme == 'https'
        end
      end

      # Executes an API request, and returns a reponse of the given type.
      #
      # @param request [Adyen::REST::Request] The API request to execute.
      #   <tt>validate!</tt> will be called on the this object before the
      #   request is made.
      # @param response_type [Class] The response type to use. Use either
      #   <tt>Adyen::REST::Response</tt> or a subclass.
      # @return [Adyen::REST::Response] A response instance of the provided type
      # @see execute_http_request The <tt>execute_http_request</tt> takes care
      #   of  executing the underlying HTTP request.
      def execute_api_call(request, response_type, response_options = {})
        request.validate!
        http_response = execute_http_request(request.flattened_attributes)
        response_type.new(http_response, response_options)
      end

      protected

      # Executes a HTTP request against Adyen's REST webservice.
      # @param flattened_attributes [Hash] A dictionary of attributes to
      #   include as POST form data.
      # @return [Net::HTTPResponse] The response from the server.
      # @raise [Adyen::REST::Error] if the HTTP response code was not 200.
      # @see #http Use the <tt>http</tt> method to set options on the underlying
      #   <tt>Net::HTTP</tt> object, like timeouts.
      def execute_http_request(flattened_attributes)
        request = Net::HTTP::Post.new(endpoint.path)
        request.basic_auth(@username, @password)
        request.set_form_data(flattened_attributes)

        case response = http.request(request)
        when Net::HTTPOK
          return response
        when Net::HTTPInternalServerError
          raise Adyen::REST::ErrorResponse.new(response.body)
        when Net::HTTPUnauthorized
          raise Adyen::REST::Error.new("Webservice credentials are incorrect")
        else
          raise Adyen::REST::Error.new("Unexpected HTTP response: #{response.code}")
        end
      end

      # The endpoint URI for this client.
      # @return [URI] The endpoint to use for the environment.
      def endpoint
        @endpoint ||= URI(ENDPOINT % [environment])
      end

      # @see Adyen::REST::Client#endpoint
      ENDPOINT = 'https://pal-%s.adyen.com/pal/adapter/httppost'
      private_constant :ENDPOINT
    end
  end
end
