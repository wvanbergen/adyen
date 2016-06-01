require 'test_helper'
require 'adyen/rest'

class PaymentModificationAPITest < Minitest::Test
  def setup
    @client = Adyen::REST.client
  end

  def teardown
    @client.close
  end

  def test_capture_payment_api_request
    response = @client.capture_payment(
      merchant_account: 'VanBergenORG',
      modification_amount: { currency: 'EUR', value: 1234 },
      reference: "functional test for cancellation",
      original_reference: 7913939284323855
    )

    assert response.received?
    assert response.psp_reference
  end

  def test_cancel_payment_api_request
    response = @client.cancel_payment(
      merchant_account: 'VanBergenORG',
      reference: "functional test for cancellation",
      original_reference: 7913939284323855
    )

    assert response.received?
    assert response.psp_reference
  end

  def test_refund_payment_api_request
    response = @client.refund_payment(
      merchant_account: 'VanBergenORG',
      modification_amount: { currency: 'EUR', value: 1234 },
      reference: "functional test for cancellation",
      original_reference: 7913939284323855
    )

    assert response.received?
    assert response.psp_reference
  end

  def test_cancel_or_refund_payment_api_request
    response = @client.cancel_or_refund_payment(
      merchant_account: 'VanBergenORG',
      reference: "functional test for cancellation",
      original_reference: 7913939284323855
    )

    assert response.received?
    assert response.psp_reference
  end
end
