require 'cgi'
require 'net/http'

module Adyen
  module REST
    ENDPOINT = 'https://pal-%s.adyen.com/pal/adapter/httppost'

    Error = Class.new(StandardError)

    class ErrorResponse < Error
      attr_accessor :category, :code, :description

      def initialize(response_body)
        if match = /\A(\w+)\s(\d+)\s(.*)\z/.match(response_body)
          @category, @code, @description = match[1], match[2], match[3]
          super("API request error: #{description} (code: #{code}/#{category})")
        else
          super("API request error: #{response_body}")
        end
      end
    end

		class Client
      attr_reader :environment

      def initialize(environment, username, password, options = {})
        @environment, @username, @password, @options = environment, username, password, options
      end

      def endpoint
        @endpoint ||= URI(Adyen::REST::ENDPOINT % [environment])
      end

      def api_request(action, attributes)
        request = Net::HTTP::Post.new(endpoint.path)
        request.basic_auth(@username, @password)
        request.set_form_data(Adyen::Util.flatten(attributes.merge(action: action)))

        response = Net::HTTP.start(endpoint.host, endpoint.port, use_ssl: endpoint.scheme == 'https') do |http|
          http.request(request)
        end

        case response
        when Net::HTTPInternalServerError
          raise Adyen::REST::ErrorResponse.new(response.body)
        when Net::HTTPUnauthorized
          raise Adyen::REST::Error.new("Webservice credentials are incorrect")
        when Net::HTTPOK
          attributes = CGI.parse(response.body)
          attributes.each { |key, values| attributes[key] = values.first }
          Adyen::Util.deflatten(attributes)
        else
          raise Adyen::REST::Error.new("Unexpected HTTP response: #{response.code}")
        end
      end
		end
  end
end
