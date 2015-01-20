require 'test_helper'

class PaymentAuthorisationAPITest < Minitest::Test
  def setup
    @client = Adyen::REST.client
  end

  def teardown
    @client.close
  end

  def test_payment_api_request
    response = @client.authorise_payment(
      merchant_account: 'VanBergenORG',
      amount: { currency: 'EUR', value: 1234 },
      reference: 'Test order #1',
      card: Adyen::TestCards::VISA
    )

    assert response.authorised?
    assert response.psp_reference
  end

  def test_refused_payment_api_request
    response = @client.authorise_payment(
      merchant_account: 'VanBergenORG',
      amount: { currency: 'EUR', value: 1234 },
      reference: 'Test order #1',
      card: Adyen::TestCards::VISA.merge(cvc: '123')
    )

    assert response.refused?
    assert response.psp_reference
    assert response.has_attribute?(:refusal_reason)
  end

  def test_payment_with_3d_secure_api_request
    response = @client.authorise_payment(
      merchant_account: 'VanBergenORG',
      amount: { currency: 'EUR', value: 1234 },
      reference: 'Test order #1',
      card: Adyen::TestCards::MASTERCARD_3DSECURE,
      browser_info: {
        acceptHeader: "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
        userAgent: "Mozilla/5.0 (X11; U; Linux i686; en-US; rv:1.9) Gecko/2008052912 Firefox/3.0"
      }
    )

    assert response.redirect_shopper?
    assert response.psp_reference
    assert response.has_attribute?(:md)
    assert_equal "https://test.adyen.com/hpp/3d/validate.shtml", response['issuer_url']
  end

  def test_initial_recurring_payment_api_request
    response = @client.authorise_recurring_payment(
      merchant_account: 'VanBergenORG',
      shopper_email: 'willem@van-bergen.org',
      shopper_reference: 'willem42',
      amount: { currency: 'EUR', value: 1234 },
      reference: 'Test initial recurring payment order #1',
      card: Adyen::TestCards::VISA
    )

    assert response.authorised?
    assert response.psp_reference
  end

  def test_recurring_payment_api_request
    response = @client.reauthorise_recurring_payment(
      merchant_account: 'VanBergenORG',
      shopper_email: 'willem@van-bergen.org',
      shopper_reference: 'willem42',
      amount: { currency: 'EUR', value: 1234 },
      reference: 'Test recurring payment order #1'
    )

    assert response.authorised?
    assert response.psp_reference
  end
end
