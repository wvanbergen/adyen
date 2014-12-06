module Adyen
  module REST
    class Request
      attr_accessor :action, :request_prefix, :response_prefix, :request_attributes

      def initialize(action, request_prefix, response_prefix, request_attributes)
        @action, @request_prefix, @response_prefix = action, request_prefix, response_prefix
        @request_attributes = request_attributes
      end

      def flattened_attributes
        Adyen::Util.flatten(request_prefix => request_attributes, :action => action)
      end

      def parse_response(http_response)
        Adyen::REST::Response.new(response_prefix, http_response)
      end
    end
  end
end
