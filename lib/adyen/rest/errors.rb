module Adyen
  module REST

    # The main exception class for error reporting when using the REST API Client.
    class Error < ::StandardError
    end

    # Exception class for error responses from the Adyen API.
    #
    # @!attribute category
    #    @return [String, nil]
    # @!attribute code
    #    @return [Integer, nil]
    # @!attribute description
    #    @return [String, nil]
    class ErrorResponse < Error
      attr_accessor :category, :code, :description

      def initialize(response_body)
        if match = /\A(\w+)\s(\d+)\s(.*)\z/.match(response_body)
          @category, @code, @description = match[1], match[2].to_i, match[3]
          super("API request error: #{description} (code: #{code}/#{category})")
        else
          super("API request error: #{response_body}")
        end
      end
    end
  end
end
