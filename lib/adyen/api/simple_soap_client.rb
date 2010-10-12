require 'net/https'

require 'adyen/api/response'
require 'adyen/api/xml_querier'

module Adyen
  module API
    class SimpleSOAPClient
      ENVELOPE = <<EOS
<?xml version="1.0"?>
<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
  <soap:Body>
    %s
  </soap:Body>
</soap:Envelope>
EOS

      class ClientError < StandardError
        def initialize(response, action, endpoint)
          @response, @action, @endpoint = response, action, endpoint
        end

        def message
          "[#{@response.code} #{@response.message}] A client error occurred while calling SOAP action `#{@action}' on endpoint `#{@endpoint}'."
        end
      end

      # from http://curl.haxx.se/ca/cacert.pem
      CACERT = File.expand_path('../cacert.pem', __FILE__)

      class << self
        attr_accessor :stubbed_response

        def endpoint
          @endpoint ||= URI.parse(const_get('ENDPOINT_URI') % Adyen.environment)
        end
      end

      attr_reader :params

      def initialize(params = {})
        @params = API.default_params.merge(params)
      end

      def call_webservice_action(action, data, response_class)
        if response = self.class.stubbed_response
          self.class.stubbed_response = nil
          response
        else
          endpoint = self.class.endpoint

          post = Net::HTTP::Post.new(endpoint.path, 'Accept' => 'text/xml', 'Content-Type' => 'text/xml; charset=utf-8', 'SOAPAction' => action)
          post.basic_auth(API.username, API.password)
          post.body = ENVELOPE % data

          request = Net::HTTP.new(endpoint.host, endpoint.port)
          request.use_ssl = true
          request.ca_file = CACERT
          request.verify_mode = OpenSSL::SSL::VERIFY_PEER

          request.start do |http|
            http_response = http.request(post)
            raise ClientError.new(http_response, action, endpoint) if http_response.is_a?(Net::HTTPClientError)
            response_class.new(http_response)
          end
        end
      end
    end
  end
end
