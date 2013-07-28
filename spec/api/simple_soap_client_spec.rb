# encoding: UTF-8
require 'api/spec_helper'

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
    uri.scheme.should == 'https'
    uri.host.should == 'test.example.com'
    uri.path.should == '/soap/Action'
  end

  it "initializes with the given parameters" do
    @client.params[:reference].should == 'order-id'
  end

  it "merges the default parameters with the given ones" do
    @client.params[:merchant_account].should == 'SuperShopper'
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
      @request.host.should == endpoint.host
      @request.port.should == endpoint.port
      @post.path.should == endpoint.path
    end

    it "makes a request over SSL" do
      @request.use_ssl?.should be_true
    end

    it "verifies certificates" do
      File.should exist(Adyen::API::SimpleSOAPClient::CACERT)
      @request.ca_file.should == Adyen::API::SimpleSOAPClient::CACERT
      @request.verify_mode.should == OpenSSL::SSL::VERIFY_PEER
    end

    it "uses basic-authentication with the credentials set on the Adyen::API module" do
      username, password = @post.assigned_basic_auth
      username.should == 'SuperShopper'
      password.should == 'secret'
    end

    it "sends the proper headers" do
      @post.header.should include(
        'accept'       => ['text/xml'],
        'content-type' => ['text/xml; charset=utf-8'],
        'soapaction'   => ['Action']
      )
    end

    it "returns an Adyen::API::Response instance" do
      @response.should be_instance_of(Adyen::API::Response)
      @response.xml_querier.to_s.should == AUTHORISE_RESPONSE
    end

    [
      [
        "[401 Bad request] A client",
        Net::HTTPBadRequest.new('1.1', '401', 'Bad request'),
        Adyen::API::SimpleSOAPClient::ClientError
      ]
    ].each do |label, response, expected_exception|
      it "raises when the HTTP response is a subclass of #{response.class.name}" do
        response.stub(:body).and_return(%{<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"><soap:Body><soap:Fault><faultcode>soap:Server</faultcode><faultstring>Illegal argument. For input string: "100.0"</faultstring></soap:Fault></soap:Body></soap:Envelope>})
        Net::HTTP.stubbed_response = response

        exception = nil
        begin
          @client.call_webservice_action('Action', '<bananas>Yes, please</bananas>', Adyen::API::Response)
        rescue expected_exception => e
          exception = e
        end
        exception.message.should ==  %{#{label} error occurred while calling SOAP action `Action' on endpoint `https://test.example.com/soap/Action'. Fault message: Illegal argument. For input string: "100.0".}
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
          response.stub(:body).and_return(%{<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"><soap:Body></soap:Body></soap:Envelope>})
          Net::HTTP.stubbed_response = response

          exception = nil
          begin
            @client.call_webservice_action('Action', '<bananas>Yes, please</bananas>', Adyen::API::Response)
          rescue Adyen::API::SimpleSOAPClient::ServerError => e
            exception = e
          end
          exception.message.should ==  %{#{label} error occurred while calling SOAP action `Action' on endpoint `https://test.example.com/soap/Action'.}
        end
      end

      it "is not raised when the HTTP response has a 500 status code with a fault message" do
        response = Net::HTTPServerError.new('1.1', '500', 'Internal Server Error')
        response.stub(:body).and_return(%{<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"><soap:Body><soap:Fault><faultcode>soap:Server</faultcode><faultstring>Illegal argument. For input string: "100.0"</faultstring></soap:Fault></soap:Body></soap:Envelope>})

        lambda do
          @client.call_webservice_action('Action', '<bananas>Yes, please</bananas>', Adyen::API::Response)
        end.should_not raise_error
      end
    end
  end
end
