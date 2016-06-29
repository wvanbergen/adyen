require 'test_helper'
require 'adyen/rest'

class PayoutAPITest < Minitest::Test
  def setup
    @client =  Adyen::REST::Client.new(
      :test,
      'storePayout@Company.VanBergen',
      'xxWWcc'
    )
  end

  def teardown
    @client.close
  end

  def test_submit_and_store_request
    response = @client.submit_and_store_payout(
      merchantAccount: 'VanBergenORG',
      amount: { currency: 'EUR', value: 20},
      bank: { iban: 'NL48RABO0132394782', bankName: 'Rabobank', countryCode: 'NL', ownerName: 'Test shopper' },
      recurring: { contract: 'PAYOUT' },
      reference: 'PayoutPayment-0001',
      shopperEmail: 'shopper@example.com',
      shopperReference: 'ShopperFoo'
    )

    assert response.received?
    assert response.psp_reference
  end

  def test_store_request
    response = @client.store_payout(
      merchantAccount: 'VanBergenORG',
      bank: { iban: 'NL48RABO0132394782', bankName: 'Rabobank', countryCode: 'NL', ownerName: 'Test shopper' },
      recurring: { contract: 'PAYOUT' },
      shopperEmail: 'shopper@example.com',
      shopperReference: 'ShopperFoo'
    )

    assert response.success?
    assert response.psp_reference
  end

  def test_submit_request
    response = @client.submit_payout(
      merchantAccount: 'VanBergenORG',
      amount: { currency: 'EUR', value: 20 },
      recurring: { contract: 'PAYOUT' },
      reference: 'PayoutPayment-0001',
      shopperEmail: 'shopper@example.com',
      shopperReference: 'ShopperFoo',
      selectedRecurringDetailReference: 'LATEST'
    )

    assert response.received?
    assert response.psp_reference
  end
end

class PayoutReviewTest < Minitest::Test
  def setup
    @client =  Adyen::REST::Client.new(
      :test,
      'reviewPayout@Company.VanBergen',
      'ssWWcc'
    )
  end

  def teardown
    @client.close
  end

  def test_confirm_payout
    response = @client.confirm_payout(
      merchantAccount: 'VanBergenORG',
      originalReference: '1234'
    )

    assert response.confirmed?
    assert response.psp_reference
  end

  def test_decline_payout
    response = @client.decline_payout(
      merchantAccount: 'VanBergenORG',
      originalReference: '1234'
    )

    assert response.declined?
    assert response.psp_reference
  end
end
