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

    it "raises when the HTTP response is a subclass of Net::HTTPClientError" do
      Net::HTTP.stubbed_response = Net::HTTPBadRequest.new('1.1', '401', 'Bad request')
      exception = nil
      begin
        @client.call_webservice_action('Action', '<bananas>Yes, please</bananas>', Adyen::API::Response)
      rescue Adyen::API::SimpleSOAPClient::ClientError => e
        exception = e
      end
      msg = "[401 Bad request] A client error occurred while calling SOAP action `Action' on endpoint `https://test.example.com/soap/Action'."
      exception.message.should == msg
    end
  end
end
