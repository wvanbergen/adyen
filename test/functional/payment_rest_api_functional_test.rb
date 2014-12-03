require 'test_helper'

class PaymentRestApiFunctionalTest < Minitest::Test
  def setup
    setup_api_configuration
    @client = Adyen::REST.client
  end

  def test_payment_api_request
    response = @client.api_request('Payment.authorise',
      payment_request: {
        merchant_account: 'VanBergenORG',
        amount: { currency: 'EUR', value: 1234 },
        reference: 'Test order #1',
        card: Adyen::TestCards::VISA
      }
    )

    assert_equal 'Authorised', response['payment_result']['result_code']
    assert response['payment_result'].key?('psp_reference')
  end

  def test_refused_payment_api_request
    response = @client.api_request('Payment.authorise',
      payment_request: {
        merchant_account: 'VanBergenORG',
        amount: { currency: 'EUR', value: 1234 },
        reference: 'Test order #1',
        card: Adyen::TestCards::VISA.merge(cvc: '123')
      }
    )

    assert_equal 'Refused', response['payment_result']['result_code']
    assert response['payment_result'].key?('psp_reference')
    assert response['payment_result'].key?('refusal_reason')
  end

  def test_payment_with_3d_secure_api_request
    response = @client.api_request('Payment.authorise',
      payment_request: {
        merchant_account: 'VanBergenORG',
        amount: { currency: 'EUR', value: 1234 },
        reference: 'Test order #1',
        card: Adyen::TestCards::MASTERCARD_3DSECURE,
        browser_info: {
          acceptHeader: "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
          userAgent: "Mozilla/5.0 (X11; U; Linux i686; en-US; rv:1.9) Gecko/2008052912 Firefox/3.0"
        }
      }
    )

    assert_equal 'RedirectShopper', response['payment_result']['result_code']
    assert response['payment_result'].key?('psp_reference')
    assert response['payment_result'].key?('md')
    assert_equal "https://test.adyen.com/hpp/3d/validate.shtml", response['payment_result']['issuer_url']
  end
end
