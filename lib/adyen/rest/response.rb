require 'adyen/rest/parse_adyen_response'


module Adyen
  module REST

    # The Response class models the HTTP response that is the result of a
    # API call to Adyen's REST webservice.
    #
    # Some API calls may respond with an instance of a subclass, to make
    # dealing with the response easier.
    #
    # @!attribute http_response [r]
    #   The underlying net/http response.
    #   @return [Net::HTTPResponse]
    # @!attribute prefix [r]
    #   The prefix to use when reading attributes from the response
    #   @return [String]
    #
    # @see Adyen::REST::Client
    # @see Adyen::REST::Request
    class Response
      include Adyen::REST::ParseReponse

      def initialize(http_response, options = {})
        @http_response = http_response
        @prefix = options.key?(:prefix) ? options[:prefix].to_s : nil
        @attributes = parse_response_attributes
      end
    end
  end
end
