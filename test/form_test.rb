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
      :delivery_address => {
        :street               => 'Pecunialaan',
        :house_number_or_name => '316',
        :city                 => 'Geldrop',
        :state_or_province    => 'None',
        :postal_code          => '1234 AB',
        :country              => 'Netherlands',
      },
      :shopper => {
        :telephone_number       => '1234512345',
        :first_name             => 'John',
        :last_name              => 'Doe',
        :social_security_number => '123-45-1234'
      },
      :openinvoicedata => {
        :number_of_lines => 1,
        :line1 => {
          :number_of_items => 2,
          :item_amount => 4000,
          :currency_code => 'GBP',
          :item_vat_amount => 1000,
          :item_vat_percentage => 2500,
          :item_vat_category => 'High',
          :description => 'Product Awesome'
        },
        :refund_description => 'Refund for 12345'
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

    signature_string = Adyen::Form.calculate_signature_string(@payment_attributes.merge(:billing_address_type => '1', :delivery_address_type => '2'))
    assert_equal "10000GBP2007-10-20Internet Order 123454aD37dJATestMerchant2007-10-11T11:00:00Z12", signature_string

    signature_string = Adyen::Form.calculate_signature_string(@payment_attributes.merge(:delivery_address_type => '2', :shopper_type => '1'))
    assert_equal "10000GBP2007-10-20Internet Order 123454aD37dJATestMerchant2007-10-11T11:00:00Z21", signature_string
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

  def test_delivery_address_signature
    signature_string = Adyen::Form.calculate_delivery_address_signature_string(@payment_attributes[:delivery_address])
    assert_equal "Pecunialaan316Geldrop1234 ABNoneNetherlands", signature_string
    assert_equal 'g8wPEWYrDPatkGXzuQbN1++JVbE=', Adyen::Form.calculate_delivery_address_signature(@payment_attributes)

    @payment_attributes.delete(:shared_secret)
    assert_raises(ArgumentError) { Adyen::Form.calculate_delivery_address_signature(@payment_attributes) }
  end

  def test_open_invoice_signature
    merchant_sig = Adyen::Form.calculate_signature(@payment_attributes, @payment_attributes[:shared_secret])
    signature_string = Adyen::Form.calculate_open_invoice_signature_string(merchant_sig, @payment_attributes[:openinvoicedata])
    expected_string =
      [
        'merchantSig',
        'openinvoicedata.line1.currencyCode',
        'openinvoicedata.line1.description',
        'openinvoicedata.line1.itemAmount',
        'openinvoicedata.line1.itemVatAmount',
        'openinvoicedata.line1.itemVatCategory',
        'openinvoicedata.line1.itemVatPercentage',
        'openinvoicedata.line1.numberOfItems',
        'openinvoicedata.numberOfLines',
        'openinvoicedata.refundDescription'
      ].join(':') +
      '|' +
      [
        merchant_sig,
        'GBP',
        'Product Awesome',
        4000,
        1000,
        'High',
        2500,
        2,
        1,
        'Refund for 12345'
      ].join(':')

    assert_equal expected_string, signature_string
    assert_equal 'OI71VGB7G3vKBRrtE6Ibv+RWvYY=', Adyen::Form.calculate_open_invoice_signature(@payment_attributes)

    @payment_attributes.delete(:shared_secret)
    assert_raises(ArgumentError) { Adyen::Form.calculate_open_invoice_signature(@payment_attributes) }
  end

  def test_billing_signatures_in_redirect_url
    get_params = CGI.parse(URI(Adyen::Form.redirect_url(@payment_attributes)).query)
    assert_equal '5KQb7VJq4cz75cqp11JDajntCY4=', get_params['billingAddressSig'].first
    assert_equal 'g8wPEWYrDPatkGXzuQbN1++JVbE=', get_params['deliveryAddressSig'].first
    assert_equal 'rb2GEs1kGKuLh255a3QRPBYXmsQ=', get_params['shopperSig'].first
    assert_equal 'OI71VGB7G3vKBRrtE6Ibv+RWvYY=', get_params['openinvoicedata.sig'].first
  end  

  def test_redirect_signature_check
    params = { 
      'authResult' => 'AUTHORISED', 'pspReference' => '1211992213193029',
      'merchantReference' => 'Internet Order 12345', 'skinCode' => '4aD37dJA',
      'merchantSig' => 'ytt3QxWoEhAskUzUne0P5VA9lPw='
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

  def test_redirect_signature_check
    Adyen.configuration.register_form_skin(:testing, 'tifSfXeX', 'testing123', :merchant_account => 'VanBergenORG')

# http://example.com/result?merchantReference=HPP+test+order+%25231&skinCode=tifSfXeX&shopperLocale=en_GB&paymentMethod=visa&authResult=AUTHORISED&pspReference=8814131153369759&merchantSig=il8cjgOiG4N9l2PlSf6h4EVQ6hk%253D
    params = {
      "merchantReference"=>CGI.unescape("HPP test order %231"), "skinCode"=>"tifSfXeX", 
      "shopperLocale"=>"en_GB", "paymentMethod"=>"visa", "authResult"=>"AUTHORISED", 
      "pspReference"=>"8814131148758652", "merchantSig"=> CGI.unescape("q8J9P%2Fp%2FYsbnnFn%2F83TFsv7Hais%3D")
    }

    assert_equal params['merchantSig'], Adyen::Form.redirect_signature(params)
  end

  def test_hidden_payment_form_fields
    payment_snippet = <<-HTML
      <form id="adyen" action="#{CGI.escapeHTML(Adyen::Form.url)}" method="post">
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
      <form id="adyen" action="#{CGI.escapeHTML(Adyen::Form.url)}" method="post">
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
