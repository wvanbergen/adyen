require 'test_helper'

class RESTResponseTest < Minitest::Test

  def setup
    @http_response = mock
    @http_response.stubs(body: 'result.a=123&result.b.c=456&result.camelCase=789')
    @response = Adyen::REST::Response.new(@http_response, prefix: 'result')
  end

  def test_getting_attributes
    assert_equal '123', @response[:a]
    assert_equal '123', @response['a']
    assert_equal '123', @response['result.a']
    assert_equal '789', @response['camelCase']
    assert_equal '789', @response[:camel_case]
  end
end
