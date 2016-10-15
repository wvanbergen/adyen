# encoding: UTF-8
require 'unit/api/test_helper'

describe Adyen::API::Response do
  before do
    http_response = Net::HTTPOK.new('1.1', '200', 'OK')
    http_response.add_field('Content-type', 'text/xml')
    allow(http_response).to receive(:body).and_return(AUTHORISE_RESPONSE)
    @response = Adyen::API::Response.new(http_response)
  end

  it "returns a XMLQuerier instance with the response body" do
    @response.xml_querier.must_be_instance_of(Adyen::API::XMLQuerier)
    @response.xml_querier.to_s.rstrip.must_equal AUTHORISE_RESPONSE.rstrip
  end

  describe "with a successful HTTP response" do
    it "returns that the (HTTP) request was a success" do
      @response.wont_be :http_failure?
      @response.must_be :success?
    end
  end

  describe "with a failed HTTP response" do
    before do
      http_response = Net::HTTPBadRequest.new('1.1', '400', 'Bad request')
      @response = Adyen::API::Response.new(http_response)
    end

    it "returns that the (HTTP) request was not a success" do
      @response.must_be :http_failure?
      @response.wont_be :success?
    end
  end

  describe "with a server error HTTP response and _no_ SOAP fault message" do
    before do
      http_response = Net::HTTPServerError.new('1.1', '500', 'Internal Server Error')
      allow(http_response).to receive(:body).and_return(%{<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"><soap:Body></soap:Body></soap:Envelope>})
      @response = Adyen::API::Response.new(http_response)
    end

    it "`server_error?` returns that the (HTTP) request did cause a server error" do
      @response.must_be :server_error?
    end
  end

  describe "with a server error HTTP response _and_ SOAP fault message" do
    before do
      http_response = Net::HTTPServerError.new('1.1', '500', 'Internal Server Error')
      allow(http_response).to receive(:body).and_return(%{<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"><soap:Body><soap:Fault><faultcode>soap:Server</faultcode><faultstring>Illegal argument. For input string: "100.0"</faultstring></soap:Fault></soap:Body></soap:Envelope>})
      @response = Adyen::API::Response.new(http_response)
    end

    it "`server_error?` returns that the (HTTP) request did not cause a server error" do
      @response.wont_be :server_error?
    end
  end
end
