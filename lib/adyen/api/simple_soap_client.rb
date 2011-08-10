require 'net/https'

require 'adyen/api/response'
require 'adyen/api/xml_querier'

module Adyen
  module API
    # The base class of the API classes that map to Adyen SOAP services.
    class SimpleSOAPClient
      # @private
      ENVELOPE = <<EOS
<?xml version="1.0"?>
<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
  <soap:Body>
    %s
  </soap:Body>
</soap:Envelope>
EOS

      # A CA file used to verify certificates when connecting to Adyen.
      #
      # @see http://curl.haxx.se/ca/cacert.pem
      CACERT = File.expand_path('../cacert.pem', __FILE__)

      class StandardError < ::StandardError
        def initialize(response, action, endpoint)
          @response, @action, @endpoint = response, action, endpoint
        end

        private

        def message_template
          %{[#{@response.http_response.code} #{@response.http_response.message}] A %s error occurred while calling SOAP action `#{@action}' on endpoint `#{@endpoint}', with fault message: #{@response.fault_message}.}
        end
      end

      class ClientError < StandardError
        def message
          message_template % "client"
        end
      end

      class ServerError < StandardError
        def message
          message_template % "server"
        end
      end

      class << self
        # When a response instance has been assigned, the subsequent call to
        # {SimpleSOAPClient#call_webservice_action} will not make a remote call, but simply return
        # the stubbed response instance. This is obviously meant for making payments from tests.
        #
        # @see PaymentService::TestHelpers
        # @see RecurringService::TestHelpers
        #
        # @return [Response] The stubbed Response subclass instance.
        attr_accessor :stubbed_response

        # @return [URI]      A URI based on the ENDPOINT_URI constant defined on subclasses, where
        #                    the environment type has been interpolated. E.g. Test environment.
        def endpoint
          @endpoint ||= URI.parse(const_get('ENDPOINT_URI') % Adyen.configuration.environment)
        end
      end

      # @return [Hash]       A hash of key-value pairs required for the action that is to be called.
      attr_reader :params

      # @param [Hash] params A hash of key-value pairs required for the action that is to be called.
      #                      These are merged with the Adyen::API.default_params.
      def initialize(params = {})
        @params = Adyen.configuration.default_api_params.merge(params)
      end

      def validate_parameter_value!(param, value)
        if value.nil? || value =~ /^\s*$/
          raise ArgumentError, "The required parameter `:#{param}' is missing."
        end
      end

      def validate_parameters!(*params)
        params.each do |param|
          case param
          when Symbol
            validate_parameter_value!(param, @params[param])
          when Hash
            param.each do |name, attrs|
              validate_parameter_value!(name, @params[name])
              attrs.each { |attr| validate_parameter_value!("#{name} => :#{attr}", @params[name][attr]) }
            end
          end
        end
      end

      # This method wraps the given XML +data+ in a SOAP envelope and posts it to +action+ on the
      # +endpoint+ defined for the subclass.
      #
      # The result is a response object, with XMLQuerier, ready to be queried.
      #
      # If a {stubbed_response} has been set, then said response is returned and no actual remote
      # calls are made.
      #
      # @param [String]   action         The remote action to call.
      # @param [String]   data           The XML data to post to the remote action.
      # @param [Response] response_class The Response subclass used to wrap the response from Adyen.
      def call_webservice_action(action, data, response_class)
        if response = self.class.stubbed_response
          self.class.stubbed_response = nil
          response
        else
          endpoint = self.class.endpoint

          post = Net::HTTP::Post.new(endpoint.path, 'Accept' => 'text/xml', 'Content-Type' => 'text/xml; charset=utf-8', 'SOAPAction' => action)
          post.basic_auth(Adyen.configuration.api_username, Adyen.configuration.api_password)
          post.body = ENVELOPE % data

          request = Net::HTTP.new(endpoint.host, endpoint.port)
          request.use_ssl = true
          request.ca_file = CACERT
          request.verify_mode = OpenSSL::SSL::VERIFY_PEER

          request.start do |http|
            http_response = http.request(post)
            response = response_class.new(http_response)
            raise ClientError.new(response, action, endpoint) if http_response.is_a?(Net::HTTPClientError)
            raise ServerError.new(response, action, endpoint) if http_response.is_a?(Net::HTTPServerError)
            response
          end
        end
      end
    end
  end
end
