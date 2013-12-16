module Adyen
  module API
    # The base class of all responses returned by API calls to Adyen.
    class Response
      # Defines shortcut accessor methods, to {Response#params}, for the given parameters.
      def self.response_attrs(*attrs)
        attrs.each do |attr|
          define_method(attr) { params[attr] }
        end
      end

      # @return [Net::HTTPResponse] The response object returned by Net::HTTP.
      attr_reader :http_response

      # @param [Net::HTTPResponse] http_response The response object returned by Net::HTTP.
      def initialize(http_response)
        @http_response = http_response
      end

      # @return [String] The raw body of the response object.
      def body
        @http_response.body
      end

      # @return [Boolean] Whether or not the request was successful.
      def success?
        !http_failure?
      end

      # @return [Boolean] Whether or not the HTTP request was a success.
      def http_failure?
        !@http_response.is_a?(Net::HTTPSuccess)
      end

      # @return [Boolean] Whether or not the SOAP request itself was a success.
      # Adyen returns a 500 status code for e.g. failed CC validation and in this case, we don't
      # want to throw a server error but rather treat it as something normal.
      def server_error?
        @http_response.is_a?(Net::HTTPServerError) && fault_message.nil?
      end

      # @return [XMLQuerier] The response body wrapped in a XMLQuerier.
      def xml_querier
        @xml_querier ||= XMLQuerier.xml(@http_response.body)
      end

      # @return [Hash] Subclasses return the parsed response body.
      def params
        raise "The Adyen::API::Response#params method should be overridden in a subclass."
      end

      # @return [String,nil] The SOAP failure message, if there is one.
      def fault_message
        @fault_message ||= begin
          message = xml_querier.text('//soap:Fault/faultstring')
          message unless message.empty?
        end
      end
    end
  end
end
