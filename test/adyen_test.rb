# encoding: UTF-8
require 'test_helper'

class AdyenTest < Minitest::Test
  def test_hmac_base64_encoding
    encoded_str = Adyen::Encoding.hmac_base64('bla', 'bla')
    assert_equal '6nItEkVpIYF+i1RwrEyQ7RHmrfU=', encoded_str
  end

  def test_gzip_base64_encoding
    encoded_str = Adyen::Encoding.gzip_base64('bla')
    assert_equal 32, encoded_str.length
  end

  def test_date_formatting
    assert_match /^\d{4}-\d{2}-\d{2}$/, Adyen::Formatter::DateTime.fmt_date(Date.today)
    assert_equal '2009-01-01', Adyen::Formatter::DateTime.fmt_date('2009-01-01')

    assert_raises(ArgumentError) { Adyen::Formatter::DateTime.fmt_date('2009-1-1') }
    assert_raises(ArgumentError) { Adyen::Formatter::DateTime.fmt_time(20090101) }
  end

  def test_timestamp_formatting
    assert_match /^\d{4}-\d{2}-\d{2}T\d{2}\:\d{2}\:\d{2}Z$/, Adyen::Formatter::DateTime.fmt_time(Time.now)
    assert_match /^\d{4}-\d{2}-\d{2}T\d{2}\:\d{2}\:\d{2}Z$/, Adyen::Formatter::DateTime.fmt_time(DateTime.now)
    assert_equal '2009-01-01T11:11:11Z', Adyen::Formatter::DateTime.fmt_time('2009-01-01T11:11:11Z')

    assert_raises(ArgumentError) { Adyen::Formatter::DateTime.fmt_time('2009-01-01 11:11:11') }
    assert_raises(ArgumentError) { Adyen::Formatter::DateTime.fmt_time(20090101111111) }
  end
end
