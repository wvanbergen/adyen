require 'test_helper'

class RestApiFunctionalTest < Minitest::Test
  def setup
    Adyen.configuration.default_api_params = { :merchant_account => 'VanBergenORG' }
    Adyen.configuration.api_username = 'ws@Company.VanBergen'
    Adyen.configuration.api_password = '7phtHzbfnzsp'

    @client = Adyen::REST.client
  end

  def test_api_request
    response = @client.api_request('Payment.authorise', 
      payment_request: {
        merchant_account: 'VanBergenORG',
        amount: { currency: 'EUR', value: 1234 },
        reference: 'Test order #1',
        card: {
          expiry_month: '08',
          expiry_year: '2018',
          holder_name: 'Testy McTesterson',
          number: '4111111111111111',
          cvc: '737', 
        }
      }
    )


    assert_equal 'Authorised', response['payment_result']['result_code']
    assert response['payment_result'].key?('psp_reference')
  end
end
