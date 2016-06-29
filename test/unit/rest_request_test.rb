require 'test_helper'
require 'adyen/rest/request'

class RESTRequestTest < Minitest::Test

  def setup
    @attributes = {
      test: 123,
      nested: {
        camel_case: '456',
      },

    }
  end

  def test_form_data
    request = Adyen::REST::Request.new('Action.Test', @attributes)

    form_data = request.form_data
    assert_equal '123',  form_data['test']
    assert_equal '456',  form_data['nested.camelCase']
  end

  def test_setting_attributes
    request = Adyen::REST::Request.new('Action.Test', @attributes)
    request[:nested] = { a: 1, b: 2 }
    request[:c] = 'hello world'
    request[:camel_case] = 'snake_case'

    assert_equal '1', request.form_data['nested.a']
    assert_equal '2', request.form_data['nested.b']
    assert_equal 'hello world', request.form_data['c']
    assert_equal 'snake_case', request.form_data['camelCase']
  end

  def test_getting_attributes
    request = Adyen::REST::Request.new('Action.Test', @attributes)
    assert_equal '123', request['test']
    assert_equal '123', request[:test]
    assert_equal '456', request['nested.camel_case']
    assert_equal '456', request['nested.camelCase']
  end
end
