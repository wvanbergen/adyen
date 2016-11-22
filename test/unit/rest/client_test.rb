require 'test_helper'
require 'adyen/rest/client'

class RESTClientTest < Minitest::Test
  def test_endpoint_dev
    client =  Adyen::REST::Client.new(
        :test,
        'login',
        'password'
    )

    assert_equal client.http.address, 'pal-test.adyen.com'
  end

  def test_endpoint_live
    client =  Adyen::REST::Client.new(
        :live,
        'login',
        'password'
    )

    assert_equal client.http.address, 'pal-live.adyen.com'
  end

  def test_endpoint_live_with_merchant
    merchant = 'merchantEndpoint'

    client =  Adyen::REST::Client.new(
        :live,
        'login',
        'password',
        merchant
    )

    assert_equal client.http.address, "#{merchant}.pal-live.adyenpayments.com"
  end
end
