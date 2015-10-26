require 'test_helper'

class HppTest < Minitest::Test
  include Adyen::Matchers
  include Adyen::Test::EachXMLBackend

  def setup
    Adyen.configuration.default_form_params[:merchant_account] = 'TestMerchant'
    Adyen.configuration.register_form_skin(:testing, '4aD37dJA', 'Kah942*$7sdp0)')
    Adyen.configuration.register_form_skin(:other, 'sk1nC0de', 'shared_secret', merchant_account: 'OtherMerchant')

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
    @test_request = @test_client.new_request
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
    attributes = {
      :currency_code => 'GBP', :payment_amount => 10000, :ship_before_date => Date.parse('2015-10-26'),
      :merchant_reference => 'Internet Order 12345', :skin => :testing, :session_validity => Time.parse('2015-10-26 10:30')
    }

    processed_attributes = {
      'currencyCode' => 'GBP', 'paymentAmount' => '10000', 'shipBeforeDate' => '2015-10-26',
      'merchantReference' => 'Internet Order 12345', 'sessionValidity' => '2015-10-26T10:30:00Z',
      'merchantAccount' => 'TestMerchant', 'skinCode' => '4aD37dJA', 'merchantSig' => 'HCpo0JhqV4PG/AUa+MxRFV7o9EtmJq9w8K6z8G+Pqy0='
    }

    redirect_uri = URI(@test_request.redirect_url(attributes))
    assert_match %r[^#{@test_client.url}], redirect_uri.to_s

    params = CGI.parse(redirect_uri.query)
    processed_attributes.each do |key, value|
      assert_equal value, params[key].first
    end
  end

  def test_redirect_url_generation_with_direct_skin_details
    attributes = {
      :currency_code => 'GBP', :payment_amount => 10000, :ship_before_date => Date.parse('2015-10-26'),
      :merchant_reference => 'Internet Order 12345', :session_validity => Time.parse('2015-10-26 10:30'),
      :merchant_account => 'OtherMerchant', :skin_code => 'sk1nC0de', :shared_secret => 'shared_secret',
    }

    processed_attributes = {
      'currencyCode' => 'GBP', 'paymentAmount' => '10000', 'shipBeforeDate' => '2015-10-26',
      'merchantReference' => 'Internet Order 12345', 'sessionValidity' => '2015-10-26T10:30:00Z',
      'merchantAccount' => 'OtherMerchant', 'skinCode' => 'sk1nC0de', 'merchantSig' => 'LhzF1G35uJumjNDJAv13u2Z2toJCr5D2Ge3569s4TJ4='
    }

    redirect_uri = URI(@test_request.redirect_url(attributes))
    assert_match %r[^#{@test_client.url}], redirect_uri.to_s

    params = CGI.parse(redirect_uri.query)
    processed_attributes.each do |key, value|
      assert_equal value, params[key].first
    end
  end

  def test_payment_methods_url_generation
    attributes = {
      :currency_code => 'GBP', :payment_amount => 10000, :ship_before_date => Date.parse('2015-10-26'),
      :merchant_reference => 'Internet Order 12345', :skin => :testing, :session_validity => Time.parse('2015-10-26 10:30')
    }

    processed_attributes = {
      'currencyCode' => 'GBP', 'paymentAmount' => '10000', 'shipBeforeDate' => '2015-10-26',
      'merchantReference' => 'Internet Order 12345', 'sessionValidity' => '2015-10-26T10:30:00Z',
      'merchantAccount' => 'TestMerchant', 'skinCode' => '4aD37dJA', 'merchantSig' => 'HCpo0JhqV4PG/AUa+MxRFV7o9EtmJq9w8K6z8G+Pqy0='
    }

    payment_methods_uri = URI(@test_request.payment_methods_url(attributes))
    assert_match %r[^#{@test_client.url(:directory)}], payment_methods_uri.to_s

    params = CGI.parse(payment_methods_uri.query)
    processed_attributes.each do |key, value|
      assert_equal value, params[key].first
    end
  end

  def test_redirect_signature_check
    params = {
      'authResult' => 'AUTHORISED', 'pspReference' => '1211992213193029',
      'merchantReference' => 'Internet Order 12345', 'skinCode' => '4aD37dJA',
      'merchantSig' => 'tjW9Tw2uVcoVHgz0g2ivjkgCd6IRqCNGMdTmx4yJSJE='
    }

    assert Adyen::HPP::Response.new(params).redirect_signature_check
    assert Adyen::HPP::Response.new(params, 'Kah942*$7sdp0)').redirect_signature_check # explicitly provided shared secret

    refute Adyen::HPP::Response.new(params.merge('skinCode' => 'sk1nC0de')).redirect_signature_check
    refute Adyen::HPP::Response.new(params, 'wrong_shared_secret').redirect_signature_check

    refute Adyen::HPP::Response.new(params.merge('pspReference' => 'tampered')).redirect_signature_check
    refute Adyen::HPP::Response.new(params.merge('merchantSig' => 'tampered')).redirect_signature_check

    assert_raises(ArgumentError) { Adyen::HPP::Response.new(nil).redirect_signature_check }
    assert_raises(ArgumentError) { Adyen::HPP::Response.new({}).redirect_signature_check }
    assert_raises(ArgumentError) { Adyen::HPP::Response.new(params.delete(:skinCode)).redirect_signature_check }
  end

  def test_hidden_payment_form_fields
    payment_snippet = <<-HTML
      <form action="#{CGI.escapeHTML(@test_client.url)}" method="post">
        #{@test_request.hidden_fields(@payment_attributes)}
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
