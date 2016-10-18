# encoding: UTF-8
require 'unit/api/test_helper'

module APISpecHelper
  class SOAPClient < Adyen::API::SimpleSOAPClient
    ENDPOINT_URI = 'https://%s.example.com/soap/Action'
  end
end

describe Adyen::API::SimpleSOAPClient do
  include APISpecHelper

  before do
    @client = APISpecHelper::SOAPClient.new(:reference => 'order-id')
  end

  it "returns the endpoint, for the current environment, from the ENDPOINT_URI constant" do
    uri = APISpecHelper::SOAPClient.endpoint
    uri.scheme.must_equal 'https'
    uri.host.must_equal 'test.example.com'
    uri.path.must_equal '/soap/Action'
  end

  it "initializes with the given parameters" do
    @client.params[:reference].must_equal 'order-id'
  end

  it "merges the default parameters with the given ones" do
    @client.params[:merchant_account].must_equal 'SuperShopper'
  end

  describe "call_webservice_action" do
    before do
      stub_net_http(AUTHORISE_RESPONSE)
      @response = @client.call_webservice_action('Action', '<bananas>Yes, please</bananas>', Adyen::API::Response)
      @request, @post = Net::HTTP.posted
    end

    after do
      Net::HTTP.stubbing_enabled = false
    end

    it "posts to the class's endpoint" do
      endpoint = APISpecHelper::SOAPClient.endpoint
      @request.host.must_equal endpoint.host
      @request.port.must_equal endpoint.port
      @post.path.must_equal endpoint.path
    end

    it "makes a request over SSL" do
      @request.must_be :use_ssl?
    end

    it "verifies certificates" do
      File.must_be :exist?, Adyen::API::SimpleSOAPClient::CACERT
      @request.ca_file.must_equal Adyen::API::SimpleSOAPClient::CACERT
      @request.verify_mode.must_equal OpenSSL::SSL::VERIFY_PEER
    end

    it "uses basic-authentication with the credentials set on the Adyen::API module" do
      username, password = @post.assigned_basic_auth
      username.must_equal 'SuperShopper'
      password.must_equal 'secret'
    end

    it "sends the proper headers" do
      @post.header.
        values_at('accept', 'content-type', 'soapaction').
        must_equal([['text/xml'], ['text/xml; charset=utf-8'], ['Action']])
    end

    it "returns an Adyen::API::Response instance" do
      @response.must_be_instance_of(Adyen::API::Response)
      @response.xml_querier.to_s.rstrip.must_equal AUTHORISE_RESPONSE.rstrip
    end

    [
      [
        "[401 Bad request] A client",
        Net::HTTPBadRequest.new('1.1', '401', 'Bad request'),
        Adyen::API::SimpleSOAPClient::ClientError
      ]
    ].each do |label, response, expected_exception|
      it "raises when the HTTP response is a subclass of #{response.class.name}" do
        response.stubs(:body).returns(%{<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"><soap:Body><soap:Fault><faultcode>soap:Server</faultcode><faultstring>Illegal argument. For input string: "100.0"</faultstring></soap:Fault></soap:Body></soap:Envelope>})
        Net::HTTP.stubbed_response = response

        exception = nil
        begin
          @client.call_webservice_action('Action', '<bananas>Yes, please</bananas>', Adyen::API::Response)
        rescue expected_exception => e
          exception = e
        end
        exception.message.must_equal  %{#{label} error occurred while calling SOAP action `Action' on endpoint `https://test.example.com/soap/Action'. Fault message: Illegal argument. For input string: "100.0".}
      end
    end

    describe 'server error' do
      [
        ["[500 Internal Server Error] A server",      Net::HTTPBadGateway.new('1.1', '500', 'Internal Server Error')],
        ["[501 Not Implemented] A server",            Net::HTTPBadGateway.new('1.1', '501', 'Not Implemented')],
        ["[502 Bad Gateway] A server",                Net::HTTPBadGateway.new('1.1', '502', 'Bad Gateway')],
        ["[503 Service Unavailable] A server",        Net::HTTPBadGateway.new('1.1', '503', 'Service Unavailable')],
        ["[504 Gateway Timeout] A server",            Net::HTTPBadGateway.new('1.1', '504', 'Gateway Timeout')],
        ["[505 HTTP Version Not Supported] A server", Net::HTTPBadGateway.new('1.1', '505', 'HTTP Version Not Supported')],
      ].each do |label, response|
        it "is raised when the HTTP response is a `real` server error by status code" do
          response.stubs(:body).returns(%{<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"><soap:Body></soap:Body></soap:Envelope>})
          Net::HTTP.stubbed_response = response

          exception = nil
          begin
            @client.call_webservice_action('Action', '<bananas>Yes, please</bananas>', Adyen::API::Response)
          rescue Adyen::API::SimpleSOAPClient::ServerError => e
            exception = e
          end
          exception.message.must_equal  %{#{label} error occurred while calling SOAP action `Action' on endpoint `https://test.example.com/soap/Action'.}
        end
      end

      it "is not raised when the HTTP response has a 500 status code with a fault message" do
        response = Net::HTTPServerError.new('1.1', '500', 'Internal Server Error')
        response.stubs(:body).returns(%{<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"><soap:Body><soap:Fault><faultcode>soap:Server</faultcode><faultstring>Illegal argument. For input string: "100.0"</faultstring></soap:Fault></soap:Body></soap:Envelope>})

        @client.call_webservice_action('Action', '<bananas>Yes, please</bananas>', Adyen::API::Response)
        pass
      end
    end
  end
end
