require 'cgi'
require 'net/http'

require 'adyen/rest/errors'
require 'adyen/rest/request'
require 'adyen/rest/response'
require 'adyen/rest/authorise_payment'
require 'adyen/rest/authorise_recurring_payment'
require 'adyen/rest/modify_payment'

module Adyen
  module REST

    # The Client class acts as a client to Adyen's REST webservice.
    #
    # @!attribute environment [r]
    #   The adyen environment to interact with. Either <tt>'live'</tt> or <tt>'test'</tt>.
    #   @return [String]
    class Client
      include AuthorisePayment
      include ModifyPayment

      attr_reader :environment, :merchant

      # @param environment [String] The Adyen environment to interface with. Either
      #   <tt>'live'</tt> or <tt>'test'</tt>.
      # @param username [String] The webservice username, e.g. <tt>ws@Company.Account</tt>
      # @param password [String] The password associated with the username
      # @param merchant [String]
      def initialize(environment, username, password, merchant = nil)
        @environment, @username, @password, @merchant = environment, username, password, merchant
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

      # Runs a client session against the Adyen REST service for the duration of the block,
      # and closes the connection afterwards.
      #
      # @yield The provided block will be called in which you can interact with the API using
      #   the provided client. The client will be closed after the block returns.
      # @return [void]
      def session
        yield(self)
      ensure
        close
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
      def execute_request(request)
        request.validate!
        http_response = execute_http_request(request)
        request.build_response(http_response)
      end

      protected

      # Executes a HTTP request against Adyen's REST webservice.
      # @param request [Adyen::REST::Request] The request to execute.
      # @return [Net::HTTPResponse] The response from the server.
      # @raise [Adyen::REST::Error] if the HTTP response code was not 200.
      # @see #http Use the <tt>http</tt> method to set options on the underlying
      #   <tt>Net::HTTP</tt> object, like timeouts.
      def execute_http_request(request)
        http_request = Net::HTTP::Post.new(endpoint.path)
        http_request.basic_auth(@username, @password)
        http_request.set_form_data(request.form_data)

        case response = http.request(http_request)
        when Net::HTTPOK
          return response
        when Net::HTTPInternalServerError
          raise Adyen::REST::ResponseError.new(response.body)
        when Net::HTTPUnauthorized
          raise Adyen::REST::Error.new("Webservice credentials are incorrect")
        else
          raise Adyen::REST::Error.new("Unexpected HTTP response: #{response.code}")
        end
      end

      # The endpoint URI for this client.
      # @return [URI] The endpoint to use for the environment.
      def endpoint
        @endpoint ||= if merchant && environment.to_sym == :live
          URI(ENDPOINT_MERCHANT_SPECIFIC % [merchant])
        else
          URI(ENDPOINT % [environment])
        end
      end

      # @see Adyen::REST::Client#endpoint
      ENDPOINT = 'https://pal-%s.adyen.com/pal/adapter/httppost'
      ENDPOINT_MERCHANT_SPECIFIC = 'https://%s.pal-live.adyenpayments.com/pal/adapter/httppost'

      private_constant :ENDPOINT, :ENDPOINT_MERCHANT_SPECIFIC
    end
  end
end
