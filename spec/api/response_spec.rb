# encoding: UTF-8
require 'api/spec_helper'

describe Adyen::API::Response do
  before do
    http_response = Net::HTTPOK.new('1.1', '200', 'OK')
    http_response.add_field('Content-type', 'text/xml')
    http_response.stub(:body).and_return(AUTHORISE_RESPONSE)
    @response = Adyen::API::Response.new(http_response)
  end

  it "returns a XMLQuerier instance with the response body" do
    @response.xml_querier.should be_instance_of(Adyen::API::XMLQuerier)
    @response.xml_querier.to_s.should == AUTHORISE_RESPONSE
  end

  describe "with a successful HTTP response" do
    it "returns that the (HTTP) request was a success" do
      @response.should_not be_a_http_failure
      @response.should be_a_success
    end
  end

  describe "with a failed HTTP response" do
    before do
      http_response = Net::HTTPBadRequest.new('1.1', '400', 'Bad request')
      @response = Adyen::API::Response.new(http_response)
    end

    it "returns that the (HTTP) request was not a success" do
      @response.should be_a_http_failure
      @response.should_not be_a_success
    end
  end

  describe "with a server error HTTP response and _no_ SOAP fault message" do
    before do
      http_response = Net::HTTPServerError.new('1.1', '500', 'Internal Server Error')
      http_response.stub(:body).and_return(%{<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"><soap:Body></soap:Body></soap:Envelope>})
      @response = Adyen::API::Response.new(http_response)
    end

    it "`server_error?` returns that the (HTTP) request did cause a server error" do
      @response.server_error?.should be_true
    end
  end

  describe "with a server error HTTP response _and_ SOAP fault message" do
    before do
      http_response = Net::HTTPServerError.new('1.1', '500', 'Internal Server Error')
      http_response.stub(:body).and_return(%{<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"><soap:Body><soap:Fault><faultcode>soap:Server</faultcode><faultstring>Illegal argument. For input string: "100.0"</faultstring></soap:Fault></soap:Body></soap:Envelope>})
      @response = Adyen::API::Response.new(http_response)
    end

    it "`server_error?` returns that the (HTTP) request did not cause a server error" do
      @response.server_error?.should be_false
    end
  end
end
