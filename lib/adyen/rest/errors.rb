require 'adyen/rest/parse_adyen_response'

module Adyen
  module REST

    # The main exception class for error reporting when using the REST API Client.
    class Error < Adyen::Error
    end

    # Exception class for errors on requests
    class RequestValidationFailed < Adyen::REST::Error
    end

    # Exception class for error responses from the Adyen API.
    #
    # @!attribute category
    #    @return [String, nil]
    # @!attribute code
    #    @return [String, nil]
    # @!attribute description
    #    @return [String, nil]
    # @!attribute psp_reference
    #    @return [Integer, nil]
    class ResponseError < Adyen::REST::Error
      include Adyen::REST::ParseReponse

      def initialize(response)
        @http_response = response
        @attributes = parse_response_attributes

        if @attributes[:message]
          super("API request error: #{attributes['message']} (code: #{attributes['errorCode']}/#{ attributes['errorType']})")
        else
          super("Unexpected HTTP response code: #{response.code} | response body: #{response.body}")
        end
      end

      # Aliases
      def category
        @attributes['errorType']
      end

      def code
        @attributes['errorCode']
      end

      def description
        @attributes['message']
      end
    end
  end
end
