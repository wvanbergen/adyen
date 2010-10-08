require File.expand_path('../spec_helper', __FILE__)

describe Adyen::API::Response do
  before do
    http_response = Net::HTTPOK.new('1.1', '200', 'OK')
    http_response.add_field('Content-type', 'text/xml')
    http_response.stub!(:body).and_return(AUTHORISE_RESPONSE)
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
end
