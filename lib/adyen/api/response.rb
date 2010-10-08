module Adyen
  module API
    class Response
      def self.response_attrs(*attrs)
        attrs.each do |attr|
          define_method(attr) { params[attr] }
        end
      end

      attr_reader :http_response

      def initialize(http_response)
        @http_response = http_response
      end

      # @return [Boolean] Whether or not the request was successful.
      def success?
        !http_failure?
      end

      # @return [Boolean] Whether or not the HTTP request was a success.
      def http_failure?
        !@http_response.is_a?(Net::HTTPSuccess)
      end

      def xml_querier
        @xml_querier ||= XMLQuerier.new(@http_response.body)
      end

      def params
        raise "The Adyen::API::Response#params method should be overriden in a subclass."
      end
    end
  end
end
