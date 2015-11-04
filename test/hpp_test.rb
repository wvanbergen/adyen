require 'test_helper'

class HppTest < Minitest::Test
  include Adyen::Matchers
  include Adyen::Test::EachXMLBackend

  def setup
    @shared_secret_testing = '4468D9782DEF54FCD706C9100C71EC43932B1EBC2ACF6BA0560C05AAA7550C48'
    @shared_secret_other = '21F58626031F08A30F6BD07BB8AC12C19B56F6C99C6E1DA991A52A1C64A4C010'

    Adyen.configuration.default_form_params[:merchant_account] = 'TestMerchant'
    Adyen.configuration.register_form_skin(:testing, '4aD37dJA', @shared_secret_testing)
    Adyen.configuration.register_form_skin(:other, 'sk1nC0de', @shared_secret_other, merchant_account: 'OtherMerchant')

    # Use autodetection for the environment unless otherwise specified
    Adyen.configuration.environment = nil
    Adyen.configuration.payment_flow = :select
    Adyen.configuration.payment_flow_domain = nil
    Adyen.configuration.default_skin = :testing

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
      :skin               => :other,
      :recurring_contract => 'DEFAULT',
      :shopper_reference  => 'grasshopper52',
      :shopper_email      => 'gras.shopper@somewhere.org'
    )

    @test_client = Adyen::HPP::Client.new
  end

  def test_autodetected_redirect_url
    assert_equal 'https://test.adyen.com/hpp/select.shtml', @test_client.url

    Adyen.configuration.stubs(:autodetect_environment).returns('live')
    assert_equal 'https://live.adyen.com/hpp/select.shtml', Adyen::HPP::Client.new.url
  end

  def test_explicit_redirect_url
    assert_equal 'https://live.adyen.com/hpp/select.shtml', Adyen::HPP::Client.new(:live).url
    assert_equal 'https://test.adyen.com/hpp/select.shtml', Adyen::HPP::Client.new(:test).url

    Adyen.configuration.environment = :live
    assert_equal 'https://live.adyen.com/hpp/select.shtml', Adyen::HPP::Client.new.url
  end

  def test_redirect_url_for_different_payment_flows
    Adyen.configuration.payment_flow = :select
    assert_equal 'https://test.adyen.com/hpp/select.shtml', @test_client.url

    Adyen.configuration.payment_flow = :pay
    assert_equal 'https://test.adyen.com/hpp/pay.shtml', @test_client.url

    Adyen.configuration.payment_flow = :details
    assert_equal 'https://test.adyen.com/hpp/details.shtml', @test_client.url
  end

  def test_redirect_url_for_custom_domain
    Adyen.configuration.payment_flow_domain = "checkout.mydomain.com"
    assert_equal 'https://checkout.mydomain.com/hpp/select.shtml', @test_client.url
  end

  def test_redirect_url_generation
    request = @test_client.new_request(:testing)

    attributes = {
      :currency_code => 'GBP', :payment_amount => 10000, :ship_before_date => Date.parse('2015-10-26'),
      :merchant_reference => 'Internet Order 12345', :session_validity => Time.parse('2015-10-26 10:30')
    }

    processed_attributes = {
      'currencyCode' => 'GBP', 'paymentAmount' => '10000', 'shipBeforeDate' => '2015-10-26',
      'merchantReference' => 'Internet Order 12345', 'sessionValidity' => '2015-10-26T10:30:00Z',
      'merchantAccount' => 'TestMerchant', 'skinCode' => '4aD37dJA', 'merchantSig' => 'wwTSfepCgntaoyolDuNoKObsN7HhvSiNxcqOZr3tV14='
    }

    redirect_uri = URI(request.redirect_url(attributes))
    assert_match %r[^#{@test_client.url}], redirect_uri.to_s

    params = CGI.parse(redirect_uri.query)
    processed_attributes.each do |key, value|
      assert_equal value, params[key].first
    end
  end

  def test_redirect_url_generation_with_direct_skin_details
    request = @test_client.new_request(:other)

    attributes = {
      :currency_code => 'GBP', :payment_amount => 10000, :ship_before_date => Date.parse('2015-10-26'),
      :merchant_reference => 'Internet Order 12345', :session_validity => Time.parse('2015-10-26 10:30'),
      :merchant_account => 'OtherMerchant'
    }

    processed_attributes = {
      'currencyCode' => 'GBP', 'paymentAmount' => '10000', 'shipBeforeDate' => '2015-10-26',
      'merchantReference' => 'Internet Order 12345', 'sessionValidity' => '2015-10-26T10:30:00Z',
      'merchantAccount' => 'OtherMerchant', 'skinCode' => 'sk1nC0de', 'merchantSig' => '3vYCvD4BMBWuFcotHzbkUPIZ0EF332cLKJKLyk2PRT8='
    }

    redirect_uri = URI(request.redirect_url(attributes))
    assert_match %r[^#{@test_client.url}], redirect_uri.to_s

    params = CGI.parse(redirect_uri.query)
    processed_attributes.each do |key, value|
      assert_equal value, params[key].first
    end
  end

  def test_payment_methods_url_generation
    request = @test_client.new_request(:testing)

    attributes = {
      :currency_code => 'GBP', :payment_amount => 10000, :ship_before_date => Date.parse('2015-10-26'),
      :merchant_reference => 'Internet Order 12345', :session_validity => Time.parse('2015-10-26 10:30')
    }

    processed_attributes = {
      'currencyCode' => 'GBP', 'paymentAmount' => '10000', 'shipBeforeDate' => '2015-10-26',
      'merchantReference' => 'Internet Order 12345', 'sessionValidity' => '2015-10-26T10:30:00Z',
      'merchantAccount' => 'TestMerchant', 'skinCode' => '4aD37dJA', 'merchantSig' => 'wwTSfepCgntaoyolDuNoKObsN7HhvSiNxcqOZr3tV14='
    }

    payment_methods_uri = URI(request.payment_methods_url(attributes))
    assert_match %r[^#{@test_client.url(:directory)}], payment_methods_uri.to_s

    params = CGI.parse(payment_methods_uri.query)
    processed_attributes.each do |key, value|
      assert_equal value, params[key].first
    end
  end

  def test_has_valid_signature
    params = {
      'authResult' => 'AUTHORISED', 'pspReference' => '1211992213193029',
      'merchantReference' => 'Internet Order 12345', 'skinCode' => '4aD37dJA',
      'merchantSig' => 'KJHViiWW07uQvL62iXbkwks3BMHjoXDLdXw0M4k63WY='
    }

    correct_secret = @shared_secret_testing
    incorrect_secret = @shared_secret_other

    assert Adyen::HPP::Response.new(params).has_valid_signature?
    assert Adyen::HPP::Response.new(params, correct_secret).has_valid_signature?

    refute Adyen::HPP::Response.new(params.merge('skinCode' => 'sk1nC0de')).has_valid_signature?
    refute Adyen::HPP::Response.new(params, incorrect_secret).has_valid_signature?

    refute Adyen::HPP::Response.new(params.merge('pspReference' => 'tampered')).has_valid_signature?
    refute Adyen::HPP::Response.new(params.merge('merchantSig' => 'tampered')).has_valid_signature?

    assert_raises(ArgumentError) { Adyen::HPP::Response.new(nil).has_valid_signature? }
    assert_raises(ArgumentError) { Adyen::HPP::Response.new({}).has_valid_signature? }
    assert_raises(ArgumentError) { Adyen::HPP::Response.new(params.delete(:skinCode)).has_valid_signature? }
  end

  def test_hidden_payment_form_fields
    payment_snippet = <<-HTML
      <form action="#{CGI.escapeHTML(@test_client.url)}" method="post">
        #{@test_client.new_request(:testing).hidden_fields(@payment_attributes)}
      </form>
    HTML

    for_each_xml_backend do
      assert_adyen_single_payment_form payment_snippet,
        merchantAccount: 'TestMerchant',
        currencyCode: 'GBP',
        paymentAmount: '10000',
        skinCode: '4aD37dJA'
    end
  end

  def test_hidden_recurring_payment_form_fields
    recurring_snippet = <<-HTML
      <form action="#{CGI.escapeHTML(@test_client.url)}" method="post">
        #{@test_client.new_request(:other).hidden_fields(@recurring_payment_attributes)}
      </form>
    HTML

    for_each_xml_backend do
      assert_adyen_recurring_payment_form recurring_snippet,
        merchantAccount: 'OtherMerchant',
        currencyCode: 'GBP',
        paymentAmount: '10000',
        recurringContract: 'DEFAULT',
        skinCode: 'sk1nC0de'
    end
  end
end
