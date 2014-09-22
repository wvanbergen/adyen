require 'test_helper'

class FormTest < Minitest::Test
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

    @payment_attributes = { 
      :skin => :testing, 
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

    Adyen::Form.do_parameter_transformations!(@payment_attributes)
    Adyen::Form.do_parameter_transformations!(@recurring_payment_attributes)
  end

  def test_autodetected_redirect_url
    assert_equal 'https://test.adyen.com/hpp/select.shtml', Adyen::Form.url

    Adyen.configuration.stubs(:autodetect_environment).returns('live')
    assert_equal 'https://live.adyen.com/hpp/select.shtml', Adyen::Form.url
  end

  def test_explicit_redirect_url
    assert_equal 'https://live.adyen.com/hpp/select.shtml', Adyen::Form.url(:live)
    assert_equal 'https://test.adyen.com/hpp/select.shtml', Adyen::Form.url(:test)

    Adyen.configuration.environment = :live
    assert_equal 'https://live.adyen.com/hpp/select.shtml', Adyen::Form.url
  end

  def test_redirect_url_for_different_payment_flows
    Adyen.configuration.payment_flow = :select
    assert_equal 'https://test.adyen.com/hpp/select.shtml', Adyen::Form.url

    Adyen.configuration.payment_flow = :pay
    assert_equal 'https://test.adyen.com/hpp/pay.shtml', Adyen::Form.url

    Adyen.configuration.payment_flow = :details
    assert_equal 'https://test.adyen.com/hpp/details.shtml', Adyen::Form.url
  end

  def test_redirect_url_for_custom_domain
    Adyen.configuration.payment_flow_domain = "checkout.mydomain.com"
    assert_equal 'https://checkout.mydomain.com/hpp/select.shtml', Adyen::Form.url
  end

  def test_redirect_url_generation
    attributes = { 
      :currency_code => 'GBP', :payment_amount => 10000, :ship_before_date => Date.today,
      :merchant_reference => 'Internet Order 12345', :skin => :testing, :session_validity => Time.now + 3600 
    }

    redirect_uri = URI(Adyen::Form.redirect_url(attributes))
    assert_match %r[^#{Adyen::Form.url}], redirect_uri.to_s

    params = CGI.parse(redirect_uri.query)
    attributes.each do |key, value|
      assert_equal value.to_s, params[Adyen::Util.camelize(key).to_s].first
    end

    assert params.key?('merchantSig'), "Expected a merchantSig parameter to be set"
  end

  def test_payment_methods_url_generation
    attributes = { 
      :currency_code => 'GBP', :payment_amount => 10000, :ship_before_date => Date.today,
      :merchant_reference => 'Internet Order 12345', :skin => :testing, :session_validity => Time.now + 3600 
    }

    redirect_uri = URI(Adyen::Form.payment_methods_url(attributes))
    assert_match %r[^#{Adyen::Form.url(nil, :directory)}], redirect_uri.to_s

    params = CGI.parse(redirect_uri.query)
    attributes.each do |key, value|
      assert_equal value.to_s, params[Adyen::Util.camelize(key).to_s].first
    end

    assert params.key?('merchantSig'), "Expected a merchantSig parameter to be set"
  end  

  def test_redirect_signature_string
    signature_string = Adyen::Form.calculate_signature_string(@payment_attributes)
    assert_equal "10000GBP2007-10-20Internet Order 123454aD37dJATestMerchant2007-10-11T11:00:00Z", signature_string

    signature_string = Adyen::Form.calculate_signature_string(@payment_attributes.merge(:merchant_return_data => 'testing123'))
    assert_equal "10000GBP2007-10-20Internet Order 123454aD37dJATestMerchant2007-10-11T11:00:00Ztesting123", signature_string

    signature_string = Adyen::Form.calculate_signature_string(@recurring_payment_attributes)
    assert_equal "10000GBP2007-10-20Internet Order 12345sk1nC0deOtherMerchant2007-10-11T11:00:00Zgras.shopper@somewhere.orggrasshopper52DEFAULT", signature_string
  end

  def test_redirect_signature
    assert_equal 'x58ZcRVL1H6y+XSeBGrySJ9ACVo=', Adyen::Form.calculate_signature(@payment_attributes)
    assert_equal 'EZtZS/33I6qsXptTfRIFMJxeKFE=', Adyen::Form.calculate_signature(@recurring_payment_attributes)

    @payment_attributes.delete(:shared_secret)
    assert_raises(ArgumentError) { Adyen::Form.calculate_signature(@payment_attributes) }
  end

  def test_shopper_signature
    signature_string = Adyen::Form.calculate_shopper_signature_string(@payment_attributes[:shopper])
    assert_equal "JohnDoe1234512345", signature_string
    assert_equal 'rb2GEs1kGKuLh255a3QRPBYXmsQ=', Adyen::Form.calculate_shopper_signature(@payment_attributes)

    @payment_attributes.delete(:shared_secret)
    assert_raises(ArgumentError) { Adyen::Form.calculate_shopper_signature(@payment_attributes) } 
  end

  def test_billing_address_signature
    signature_string = Adyen::Form.calculate_billing_address_signature_string(@payment_attributes[:billing_address])
    assert_equal "Alexanderplatz0815Berlin10119BerlinGermany", signature_string
    assert_equal '5KQb7VJq4cz75cqp11JDajntCY4=', Adyen::Form.calculate_billing_address_signature(@payment_attributes)

    @payment_attributes.delete(:shared_secret)
    assert_raises(ArgumentError) { Adyen::Form.calculate_billing_address_signature(@payment_attributes) } 
  end

  def test_billing_address_and_shopper_signature_in_redirect_url
    get_params = CGI.parse(URI(Adyen::Form.redirect_url(@payment_attributes)).query)
    assert_equal '5KQb7VJq4cz75cqp11JDajntCY4=', get_params['billingAddressSig'].first
    assert_equal 'rb2GEs1kGKuLh255a3QRPBYXmsQ=', get_params['shopperSig'].first
  end  

  def test_redirect_signature_check
    params = { 
      :authResult => 'AUTHORISED', :pspReference => '1211992213193029',
      :merchantReference => 'Internet Order 12345', :skinCode => '4aD37dJA',
      :merchantSig => 'ytt3QxWoEhAskUzUne0P5VA9lPw='
    }

    assert_equal params[:merchantSig], Adyen::Form.redirect_signature(params)
    
    assert Adyen::Form.redirect_signature_check(params) # shared secret from registered skin
    assert Adyen::Form.redirect_signature_check(params, 'Kah942*$7sdp0)') # explicitly provided shared secret
    
    refute Adyen::Form.redirect_signature_check(params.merge(skinCode: 'sk1nC0de'))
    refute Adyen::Form.redirect_signature_check(params, 'wrong_shared_secret')

    refute Adyen::Form.redirect_signature_check(params.merge(pspReference: 'tampered'))
    refute Adyen::Form.redirect_signature_check(params.merge(merchantSig: 'tampered'))

    assert_raises(ArgumentError) { Adyen::Form.redirect_signature_check(nil) }
    assert_raises(ArgumentError) { Adyen::Form.redirect_signature_check({}) }
    assert_raises(ArgumentError) { Adyen::Form.redirect_signature_check(params.delete(:skinCode)) }
  end

  def test_hidden_payment_form_fields
    payment_snippet = <<-HTML
      <form action="#{CGI.escapeHTML(Adyen::Form.url)}" method="post">
        #{Adyen::Form.hidden_fields(@payment_attributes)}
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
      <form action="#{CGI.escapeHTML(Adyen::Form.url)}" method="post">
        #{Adyen::Form.hidden_fields(@recurring_payment_attributes)}
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
