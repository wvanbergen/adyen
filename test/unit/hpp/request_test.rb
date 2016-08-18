require 'test_helper'
require 'adyen/hpp/request'

class HPPRequestTest < Minitest::Test
  def setup
    Adyen.configuration.default_form_params[:merchant_account] = 'TestMerchant'
    Adyen.configuration.default_skin = :skin1

    # Use autodetection for the environment unless otherwise specified
    Adyen.configuration.environment = nil
    Adyen.configuration.payment_flow = :select
    Adyen.configuration.payment_flow_domain = nil
    Adyen.configuration.default_skin = :skin1

    @raw_params = {
      :merchant_account => 'TestMerchant',
      :currency_code => 'EUR',
      :payment_amount => '199',
      :session_validity => '2015-06-25T10:31:06Z',
      :ship_before_date => '2015-07-01',
      :shopper_locale => 'en_GB',
      :merchant_reference => 'SKINTEST-1435226439255',
      :skin_code => 'X7hsNDWp',
    }
  end

  def test_formatted_parameters
    expected_parameters = {
      merchant_account: "TestMerchant",
      currency_code: "EUR",
      payment_amount: "199",
      session_validity: "2015-06-25T10:31:06Z",
      ship_before_date: "2015-07-01",
      shopper_locale: "en_GB",
      merchant_reference: "SKINTEST-1435226439255",
      skin_code: "X7hsNDWp"}

    parameters = Adyen::HPP::Request.new(@raw_params).formatted_parameters
    assert_equal parameters, expected_parameters
  end

  def test_formatted_parameters_without_parameters
    request = Adyen::HPP::Request.new('String')

    exception = assert_raises(ArgumentError) { request.formatted_parameters }
    assert_equal("Cannot generate request: parameters should be a hash!", exception.message)
  end

  def test_formatted_parameters_without_currency_code
    @raw_params.delete(:currency_code)
    request = Adyen::HPP::Request.new(@raw_params)

    exception = assert_raises(ArgumentError) { request.formatted_parameters }
    assert_equal("Cannot generate request: :currency_code attribute not found!", exception.message)
  end

  def test_formatted_parameters_missing_parameters
    Adyen.configuration.default_form_params[:merchant_account] = nil
    Adyen.configuration.default_skin = 'unknown_skin'
    %i(currency_code payment_amount merchant_account skin_code ship_before_date session_validity).each do |parameter|
      params = @raw_params.reject { |param| param == parameter }
      request = Adyen::HPP::Request.new(params)

      exception = assert_raises(ArgumentError) { request.formatted_parameters }
      assert_equal("Cannot generate request: :#{parameter} attribute not found!", exception.message)
    end
  end
end
