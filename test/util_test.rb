# encoding: UTF-8
require 'test_helper'

class UtilTest < Minitest::Test
  def test_hmac_base64_encoding
    encoded_str = Adyen::Util.hmac_base64('bla', 'bla')
    assert_equal '6nItEkVpIYF+i1RwrEyQ7RHmrfU=', encoded_str
  end

  def test_gzip_base64_encoding
    encoded_str = Adyen::Util.gzip_base64('bla')
    assert_equal 32, encoded_str.length
  end

  def test_date_formatting
    assert_match /^\d{4}-\d{2}-\d{2}$/, Adyen::Util.format_date(Date.today)
    assert_equal '2009-01-01', Adyen::Util.format_date('2009-01-01')

    assert_raises(ArgumentError) { Adyen::Util.format_date('2009-1-1') }
    assert_raises(ArgumentError) { Adyen::Util.format_timestamp(20090101) }
  end

  def test_timestamp_formatting
    assert_match /^\d{4}-\d{2}-\d{2}T\d{2}\:\d{2}\:\d{2}Z$/, Adyen::Util.format_timestamp(Time.now)
    assert_match /^\d{4}-\d{2}-\d{2}T\d{2}\:\d{2}\:\d{2}Z$/, Adyen::Util.format_timestamp(DateTime.now)
    assert_equal '2009-01-01T11:11:11Z', Adyen::Util.format_timestamp('2009-01-01T11:11:11Z')

    assert_raises(ArgumentError) { Adyen::Util.format_timestamp('2009-01-01 11:11:11') }
    assert_raises(ArgumentError) { Adyen::Util.format_timestamp(20090101111111) }
  end

  def test_camelize
    assert_equal 'helloCruelWorld', Adyen::Util.camelize(:hello_cruel_world)
    assert_equal 'HelloWorld', Adyen::Util.camelize('_hello__world')
    assert_equal 'shopperIP', Adyen::Util.camelize('shopper_ip')
  end

  def test_underscore
    assert_equal 'hello_cruel_world', Adyen::Util.underscore('HelloCruelWorld')
    assert_equal 'rest_api', Adyen::Util.underscore('RESTApi')
    assert_equal 'shopper_ip', Adyen::Util.underscore('shopperIP')
  end

  def test_flatten
    expected_hash = { 'billingAddress.street' => 'My Street' }
    assert_equal expected_hash, Adyen::Util.flatten(:billing_address => { :street => 'My Street'})

    assert_equal Hash.new, Adyen::Util.flatten(nil)
    assert_equal Hash.new, Adyen::Util.flatten({})
  end

  def test_deflatten
    expected_hash = {
      "payment_details" => {
        "billing_address" => {
          "street" => "Bell Street",
          "number" => 123,
          "city" => "Ottawa"
        },
        "result" => "Authorized",
        "auth_code" => "A40B8"
      }
    }

    assert_equal expected_hash, Adyen::Util.deflatten(
      'paymentDetails.billingAddress.street' => 'Bell Street',
      'paymentDetails.billingAddress.number' => 123,
      'paymentDetails.billingAddress.city'   => 'Ottawa',
      'paymentDetails.result' => 'Authorized',
      'paymentDetails.authCode' => 'A40B8',
    )

    assert_raises(ArgumentError) { Adyen::Util.deflatten('a' => 1, 'a.b' => 2) }
    assert_equal Hash.new, Adyen::Util.deflatten(nil)
    assert_equal Hash.new, Adyen::Util.deflatten({})
  end
end
