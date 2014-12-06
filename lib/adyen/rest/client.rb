require 'cgi'
require 'net/http'

require 'adyen/rest/errors'
require 'adyen/rest/request'
require 'adyen/rest/response'
require 'adyen/rest/authorise_payment'

module Adyen
  module REST

    # The Client class acts as a client to Adyen's REST API
    #
    # @!attribute environment
    #   The adyen environment to interact with. Either `live` or `test`.
    #   @return [String]
    class Client
      include AuthorisePayment

      attr_reader :environment

      def initialize(environment, username, password, options = {})
        @environment, @username, @password, @options = environment, username, password, options
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

      def execute_api_call(request)
        http_response = execute_http_request(request.flattened_attributes)
        request.parse_response(http_response)
      end

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

      protected

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
