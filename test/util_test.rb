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

  def test_flatten
    parameters = { 'billingAddress.street' => 'My Street' }
    assert_equal parameters, Adyen::Util.flatten(:billing_address => { :street => 'My Street'})
    assert_equal Hash.new, Adyen::Util.flatten(nil)
  end
end
