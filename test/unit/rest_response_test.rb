require 'test_helper'
require 'adyen/rest/response'

class RESTResponseTest < Minitest::Test

  def setup
    @http_response = mock
    @http_response.stubs(body: 'result.a=123&result.b.c=456&result.camelCase=789&result.pspReference=ABC123')
    @response = Adyen::REST::Response.new(@http_response, prefix: 'result')
  end

  def test_getting_attributes
    assert_equal '123', @response[:a]
    assert_equal '123', @response['a']
    assert_equal '123', @response['result.a']
    assert_equal '789', @response['camelCase']
    assert_equal '789', @response[:camel_case]
    assert_equal 'ABC123', @response[:psp_reference]
    assert_equal 'ABC123', @response.psp_reference
  end
end
