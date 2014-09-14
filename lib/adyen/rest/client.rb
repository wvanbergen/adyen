require 'net/http'

module Adyen
  module REST
    class Client
      attr_reader :configuration

      def initialize(configuration = Adyen.configuration)
        @configuration = configuration
      end


      def authorise_payment(parameters = {})
        api_call('Payment.authorise', parameters) 
      end

      def parse_response(response)
        pairs = response.split('&').map { |pair| pair.split('=', 2).map { |i| CGI.unescape(i) } }
        pairs.inject({}) do |carry, (key, value)| 

          add_pair_to_nested_hash(key, value, carry)
        end
      end

      def add_pair_to_nested_hash(key, value, hash)
        head, rest = key.split('.', 2)
        if rest.nil?
          hash[head.to_sym] = value
        else
          hash[head.to_sym] ||= {}
          add_pair_to_nested_hash(rest, value, hash[head.to_sym])
        end
        hash
      end

      def api_call(action, parameters)
        endpoint = URI.parse("https://pal-%s.adyen.com/pal/adapter/httppost" % configuration.environment)

        http = Net::HTTP.new(endpoint.host, endpoint.port)
        http.use_ssl = endpoint.scheme == 'https'
        http.ca_file = Adyen::REST::CA_FILE
        http.verify_mode = OpenSSL::SSL::VERIFY_PEER

        request = Net::HTTP::Post.new(endpoint)
        request.basic_auth(configuration.api_username, configuration.api_password)
        request.set_form_data(parameters.merge(action: action))

        http.start do |http|
          response = http.request(request)
          p response.class
          case response
            when Net::HTTPUnauthorized; raise Adyen::REST::Unauthorized, "Unauthorized. Please check your credentials."
            when Net::HTTPServerError; raise Adyen::REST::Error, response.body
            else parse_response(response.body)
          end
        end
      end
    end
  end
end

