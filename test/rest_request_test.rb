require 'test_helper'

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
    request = Adyen::REST::Request.new('Test', @attributes, prefix: 'prefix')
    assert_equal 'Test', request.action

    form_data = request.form_data
    assert_equal 'Test', form_data['action']
    assert_equal '123',  form_data['prefix.test']
    assert_equal '456',  form_data['prefix.nested.camelCase']
  end

  def test_action_is_required
    request = Adyen::REST::Request.new(nil, @attributes)
    assert_raises(Adyen::REST::RequestValidationFailed) { request.validate! }
  end

  def test_setting_attributes
    request = Adyen::REST::Request.new('Test', @attributes, prefix: 'prefix')
    request[:nested] = { a: 1, b: 2 }
    request[:c] = 'hello world'
    request[:camel_case] = 'snake_case'

    assert_equal '1', request.form_data['prefix.nested.a']
    assert_equal '2', request.form_data['prefix.nested.b']
    assert_equal 'hello world', request.form_data['prefix.c']
    assert_equal 'snake_case', request.form_data['prefix.camelCase']
  end

  def test_getting_attributes
    request = Adyen::REST::Request.new('Test', @attributes, prefix: 'prefix')
    assert_equal '123', request['test']
    assert_equal '123', request[:test]
    assert_equal '456', request['nested.camel_case']
    assert_equal '456', request['prefix.nested.camel_case']
    assert_equal '456', request['prefix.nested.camelCase']
  end
end
