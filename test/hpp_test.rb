require 'test_helper'

class HppTest < Minitest::Test
  include Adyen::Matchers
  include Adyen::Test::EachXMLBackend

  def setup
    @skin_code1 = 'abcdefgh'
    @skin_code2 = 'ijklmnop'
    @shared_secret_skin1 = '4468D9782DEF54FCD706C9100C71EC43932B1EBC2ACF6BA0560C05AAA7550C48'
    @shared_secret_skin2 = '21F58626031F08A30F6BD07BB8AC12C19B56F6C99C6E1DA991A52A1C64A4C010'

    Adyen.configuration.default_form_params[:merchant_account] = 'TestMerchant'
    Adyen.configuration.register_form_skin(:skin1, @skin_code1, @shared_secret_skin1)
    Adyen.configuration.register_form_skin(:skin2, @skin_code2, @shared_secret_skin2, merchant_account: 'OtherMerchant')

    # Use autodetection for the environment unless otherwise specified
    Adyen.configuration.environment = nil
    Adyen.configuration.payment_flow = :select
    Adyen.configuration.payment_flow_domain = nil
    Adyen.configuration.default_skin = :skin1

    @payment_attributes = {
      :currency_code => 'GBP',
      :payment_amount => 10000,
      :merchant_reference => 'Internet Order 12345',
      :ship_before_date => '2007-10-20',
      :session_validity => '2007-10-11T11:00:00Z',
      :billing_address => {
        :street               => 'Alexanderplatz',
        :house_number_or_name => '0815',
        :city                 => 'Berlin',
        :postal_code          => '10119',
        :state_or_province    => 'Berlin',
        :country              => 'Germany',
      },
      :shopper => {
        :telephone_number       => '1234512345',
        :first_name             => 'John',
        :last_name              => 'Doe',
        :social_security_number => '123-45-1234'
      }
    }

    @recurring_payment_attributes = @payment_attributes.merge(
      :recurring_contract => 'DEFAULT',
      :shopper_reference  => 'grasshopper52',
      :shopper_email      => 'gras.shopper@somewhere.org'
    )

    @request_skin1_test = Adyen::HPP::Request.new(:skin1, :test)
    @request_skin1_live = Adyen::HPP::Request.new(:skin1, :live)
    @request_skin2_test = Adyen::HPP::Request.new(:skin2, :test)
    @request_skin2_live = Adyen::HPP::Request.new(:skin2, :live)
  end

  def test_autodetected_redirect_url
    assert_equal 'https://test.adyen.com/hpp/select.shtml', Adyen::HPP::Request.new().url

    Adyen.configuration.stubs(:autodetect_environment).returns('live')
    assert_equal 'https://live.adyen.com/hpp/select.shtml', Adyen::HPP::Request.new(:skin1).url
  end

  def test_explicit_redirect_url
    assert_equal 'https://test.adyen.com/hpp/select.shtml', @request_skin1_test.url
    assert_equal 'https://live.adyen.com/hpp/select.shtml', @request_skin1_live.url
    assert_equal 'https://test.adyen.com/hpp/select.shtml', @request_skin2_test.url
    assert_equal 'https://live.adyen.com/hpp/select.shtml', @request_skin2_live.url
  end

  def test_redirect_url_for_different_payment_flows
    Adyen.configuration.payment_flow = :select
    assert_equal 'https://test.adyen.com/hpp/select.shtml', @request_skin1_test.url

    Adyen.configuration.payment_flow = :pay
    assert_equal 'https://test.adyen.com/hpp/pay.shtml', @request_skin1_test.url

    Adyen.configuration.payment_flow = :details
    assert_equal 'https://test.adyen.com/hpp/details.shtml', @request_skin1_test.url
  end

  def test_redirect_url_for_custom_domain
    Adyen.configuration.payment_flow_domain = "checkout.mydomain.com"
    assert_equal 'https://checkout.mydomain.com/hpp/select.shtml', @request_skin1_test.url
  end

  def test_redirect_url_generation
    attributes = {
      :currency_code => 'GBP', :payment_amount => 10000, :ship_before_date => Date.parse('2015-10-26'),
      :merchant_reference => 'Internet Order 12345', :session_validity => Time.parse('2015-10-26 10:30')
    }

    processed_attributes = {
      'currencyCode' => 'GBP', 'paymentAmount' => '10000', 'shipBeforeDate' => '2015-10-26',
      'merchantReference' => 'Internet Order 12345', 'sessionValidity' => '2015-10-26T10:30:00Z',
      'merchantAccount' => 'TestMerchant', 'skinCode' => @skin_code1, 'merchantSig' => 'ewDgqa+m3rMO6MOZfQ0ugWdwsu+otvRVBVujqGfgvb8='
    }

    redirect_uri = URI(@request_skin1_test.redirect_url(attributes))
    assert_match %r[^#{@request_skin1_test.url}], redirect_uri.to_s

    params = CGI.parse(redirect_uri.query)
    processed_attributes.each do |key, value|
      assert_equal value, params[key].first
    end
  end

  def test_redirect_url_generation_with_direct_skin_details
    attributes = {
      :currency_code => 'GBP', :payment_amount => 10000, :ship_before_date => Date.parse('2015-10-26'),
      :merchant_reference => 'Internet Order 12345', :session_validity => Time.parse('2015-10-26 10:30'),
      :merchant_account => 'OtherMerchant'
    }

    processed_attributes = {
      'currencyCode' => 'GBP', 'paymentAmount' => '10000', 'shipBeforeDate' => '2015-10-26',
      'merchantReference' => 'Internet Order 12345', 'sessionValidity' => '2015-10-26T10:30:00Z',
      'merchantAccount' => 'OtherMerchant', 'skinCode' => @skin_code2, 'merchantSig' => 'uS/tdqapxD8rQKBRzKQ9wOIiOFRmcOR3HsC8CO15Zto='
    }

    redirect_uri = URI(@request_skin2_test.redirect_url(attributes))
    assert_match %r[^#{@request_skin2_test.url}], redirect_uri.to_s

    params = CGI.parse(redirect_uri.query)
    processed_attributes.each do |key, value|
      assert_equal value, params[key].first
    end
  end

  def test_payment_methods_url_generation
    attributes = {
      :currency_code => 'GBP', :payment_amount => 10000, :ship_before_date => Date.parse('2015-10-26'),
      :merchant_reference => 'Internet Order 12345', :session_validity => Time.parse('2015-10-26 10:30')
    }

    processed_attributes = {
      'currencyCode' => 'GBP', 'paymentAmount' => '10000', 'shipBeforeDate' => '2015-10-26',
      'merchantReference' => 'Internet Order 12345', 'sessionValidity' => '2015-10-26T10:30:00Z',
      'merchantAccount' => 'TestMerchant', 'skinCode' => @skin_code1, 'merchantSig' => 'ewDgqa+m3rMO6MOZfQ0ugWdwsu+otvRVBVujqGfgvb8='
    }

    payment_methods_uri = URI(@request_skin1_test.payment_methods_url(attributes))
    assert_match %r[^#{@request_skin1_test.url(:directory)}], payment_methods_uri.to_s

    params = CGI.parse(payment_methods_uri.query)
    processed_attributes.each do |key, value|
      assert_equal value, params[key].first
    end
  end

  def test_has_valid_signature
    params = {
      'authResult' => 'AUTHORISED', 'pspReference' => '1211992213193029',
      'merchantReference' => 'Internet Order 12345', 'skinCode' => @skin_code1,
      'merchantSig' => 'owrLGxBP/l5xej5VZn8FKS1exn0qOgk0P9kmRdBBw9Q='
    }

    correct_secret = @shared_secret_skin1
    incorrect_secret = @shared_secret_skin2

    assert Adyen::HPP::Response.new(params).has_valid_signature?
    assert Adyen::HPP::Response.new(params, correct_secret).has_valid_signature?

    refute Adyen::HPP::Response.new(params.merge('skinCode' => @skin_code2)).has_valid_signature?
    refute Adyen::HPP::Response.new(params, incorrect_secret).has_valid_signature?

    refute Adyen::HPP::Response.new(params.merge('pspReference' => 'tampered')).has_valid_signature?
    refute Adyen::HPP::Response.new(params.merge('merchantSig' => 'tampered')).has_valid_signature?

    assert_raises(ArgumentError) { Adyen::HPP::Response.new(nil).has_valid_signature? }
    assert_raises(ArgumentError) { Adyen::HPP::Response.new({}).has_valid_signature? }
    assert_raises(ArgumentError) { Adyen::HPP::Response.new(params.delete(:skinCode)).has_valid_signature? }
  end

  def test_hidden_payment_form_fields
    payment_snippet = <<-HTML
      <form action="#{CGI.escapeHTML(@request_skin1_test.url)}" method="post">
        #{@request_skin1_test.hidden_fields(@payment_attributes)}
      </form>
    HTML

    for_each_xml_backend do
      assert_adyen_single_payment_form payment_snippet,
        merchantAccount: 'TestMerchant',
        currencyCode: 'GBP',
        paymentAmount: '10000',
        skinCode: @skin_code1
    end
  end

  def test_hidden_recurring_payment_form_fields
    recurring_snippet = <<-HTML
      <form action="#{CGI.escapeHTML(@request_skin2_test.url)}" method="post">
        #{@request_skin2_test.hidden_fields(@recurring_payment_attributes)}
      </form>
    HTML

    for_each_xml_backend do
      assert_adyen_recurring_payment_form recurring_snippet,
        merchantAccount: 'OtherMerchant',
        currencyCode: 'GBP',
        paymentAmount: '10000',
        recurringContract: 'DEFAULT',
        skinCode: @skin_code2
    end
  end
end
