require "#{File.dirname(__FILE__)}/spec_helper.rb"

describe Adyen::SOAP::PaymentService do

  describe '#authorise' do
    before(:all) do
      setup_mock_driver(<<EOF)
<?xml version="1.0" encoding="UTF-8"?>
<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
  <soap:Body>
    <ns1:authoriseResponse xmlns:ns1="http://payment.services.adyen.com">
      <ns1:paymentResult>
        <additionalData xmlns="http://payment.services.adyen.com" xsi:nil="true"/>
        <authCode xmlns="http://payment.services.adyen.com">1234</authCode>
        <dccAmount xmlns="http://payment.services.adyen.com" xsi:nil="true"/>
        <dccSignature xmlns="http://payment.services.adyen.com" xsi:nil="true"/>
        <fraudResult xmlns="http://payment.services.adyen.com" xsi:nil="true"/>
        <issuerUrl xmlns="http://payment.services.adyen.com" xsi:nil="true"/>
        <md xmlns="http://payment.services.adyen.com" xsi:nil="true"/>
        <paRequest xmlns="http://payment.services.adyen.com" xsi:nil="true"/>
        <pspReference xmlns="http://payment.services.adyen.com">9876543210987654</pspReference>
        <refusalReason xmlns="http://payment.services.adyen.com" xsi:nil="true"/>
        <resultCode xmlns="http://payment.services.adyen.com">Authorised</resultCode>
      </ns1:paymentResult>
    </ns1:authoriseResponse>
  </soap:Body>
</soap:Envelope>
EOF

      @response = Adyen::SOAP::PaymentService.authorise({
        :selected_recurring_detail_reference => '6543210987654321',
        :merchant_account => 'YourMerchantAccount',
        :currency => 'EUR',
        :value => '1000',
        :reference => '1234567890123456',
        :shopper_email => 'user@example.com',
        :shopper_reference => '1'
      })
    end

    context 'request' do
      before(:all) do
        @root_node = get_last_request_body.xpath('//payment:authorise/payment:paymentRequest', ns)
      end

      it 'should setup a paymentRequest' do
        @root_node.should_not be_empty
      end

      it 'should provide an selectedRecurringDetailReference' do
        @root_node.xpath('./payment:selectedRecurringDetailReference/text()', ns).to_s.should == '6543210987654321'
      end

      it 'should provide a merchantAccount' do
        @root_node.xpath('./payment:merchantAccount/text()', ns).to_s.should == 'YourMerchantAccount'
      end

      it 'should provide a currency' do
        @root_node.xpath('./payment:amount/common:currency/text()', ns).to_s.should == 'EUR'
      end

      it 'should provide a value' do
        @root_node.xpath('./payment:amount/common:value/text()', ns).to_s.should == '1000'
      end

      it 'should provide a reference' do
        @root_node.xpath('./payment:reference/text()', ns).to_s.should == '1234567890123456'
      end

      it 'should provide a shopperEmail' do
        @root_node.xpath('./payment:shopperEmail/text()', ns).to_s.should == 'user@example.com'
      end

      it 'should provide a shopperReference' do
        @root_node.xpath('./payment:shopperReference/text()', ns).to_s.should == '1'
      end
    end

    context 'response' do
      it 'should get a authorised resultcode' do
        @response[:result_code].should == 'Authorised'
      end

      it 'should get a new psp reference' do
        @response[:psp_reference].should == '9876543210987654'
      end

      it 'should get an authCode' do
        @response[:auth_code].should == '1234'
      end
    end
  end

  describe '#capture' do
    before(:all) do
      setup_mock_driver(<<EOF)
<?xml version="1.0" encoding="UTF-8"?>
<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
  <soap:Body>
    <ns1:captureResponse xmlns:ns1="http://payment.services.adyen.com">
      <ns1:captureResult>
        <pspReference xmlns="http://payment.services.adyen.com">9876543210987654</pspReference>
        <response xmlns="http://payment.services.adyen.com">[capture-received]</response>
      </ns1:captureResult>
    </ns1:captureResponse>
  </soap:Body>
</soap:Envelope>
EOF

      @response = Adyen::SOAP::PaymentService.capture({
        :merchant_account => 'YourMerchantAccount',
        :original_reference => '1234567890123456',
        :currency => 'EUR',
        :value => '1000'
      })
    end

    context 'request' do
      before(:all) do
        @root_node = get_last_request_body.xpath('//payment:capture/payment:modificationRequest', ns)
      end

      it 'should setup a modificationRequest' do
        @root_node.should_not be_empty
      end

      it 'should provide a merchantAccount' do
        @root_node.xpath('./payment:merchantAccount/text()', ns).to_s.should == 'YourMerchantAccount'
      end

      it 'should provide an originalReference' do
        @root_node.xpath('./payment:originalReference/text()', ns).to_s.should == '1234567890123456'
      end

      it 'should provide a currency' do
        @root_node.xpath('./payment:modificationAmount/common:currency/text()', ns).to_s.should == 'EUR'
      end

      it 'should provide a value' do
        @root_node.xpath('./payment:modificationAmount/common:value/text()', ns).to_s.should == '1000'
      end
    end

    context 'response' do
      it 'should get a capture-received message' do
        @response[:response].should == '[capture-received]'
      end

      it 'should get a new psp reference' do
        @response[:psp_reference].should == '9876543210987654'
      end
    end
  end

  describe "#cancel" do
    before(:all) do
      setup_mock_driver(<<EOF)
<?xml version="1.0" encoding="UTF-8"?>
<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
  <soap:Body>
    <ns1:cancelResponse xmlns:ns1="http://payment.services.adyen.com">
      <ns1:cancelResult>
        <pspReference xmlns="http://payment.services.adyen.com">9876543210987654</pspReference>
        <response xmlns="http://payment.services.adyen.com">[cancel-received]</response>
      </ns1:cancelResult>
    </ns1:cancelResponse>
  </soap:Body>
</soap:Envelope>
EOF

      @response = Adyen::SOAP::PaymentService.cancel({
        :merchant_account => 'YourMerchantAccount',
        :original_reference => '1234567890123456'
      })
    end

    context 'request' do
      before(:all) do
        @root_node = get_last_request_body.xpath('//payment:cancel/payment:modificationRequest', ns)
      end

      it 'should setup a modificationRequest' do
        @root_node.should_not be_empty
      end

      it 'should provide a merchantAccount' do
        @root_node.xpath('./payment:merchantAccount/text()', ns).to_s.should == 'YourMerchantAccount'
      end

      it 'should provide an originalReference' do
        @root_node.xpath('./payment:originalReference/text()', ns).to_s.should == '1234567890123456'
      end
    end

    context 'response' do
      it 'should get a cancel-received message' do
        @response[:response].should == '[cancel-received]'
      end

      it 'should get a new psp reference' do
        @response[:psp_reference].should == '9876543210987654'
      end
    end
  end

  describe "#refund" do
    before(:all) do
      setup_mock_driver(<<EOF)
<?xml version="1.0" encoding="UTF-8"?>
<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
  <soap:Body>
    <ns1:refundResponse xmlns:ns1="http://payment.services.adyen.com">
      <ns1:refundResult>
        <pspReference xmlns="http://payment.services.adyen.com">9876543210987654</pspReference>
        <response xmlns="http://payment.services.adyen.com">[refund-received]</response>
      </ns1:refundResult>
    </ns1:refundResponse>
  </soap:Body>
</soap:Envelope>
EOF

      @response = Adyen::SOAP::PaymentService.refund({
        :merchant_account => 'YourMerchantAccount',
        :currency => 'EUR',
        :value => '1000'
      })
    end

    context 'request' do
      before(:all) do
        @root_node = get_last_request_body.xpath('//payment:refund/payment:modificationRequest', ns)
      end

      it 'should setup a modificationRequest' do
        @root_node.should_not be_empty
      end

      it 'should provide a merchantAccount' do
        @root_node.xpath('./payment:merchantAccount/text()', ns).to_s.should == 'YourMerchantAccount'
      end

      it 'should provide a currency' do
        @root_node.xpath('./payment:modificationAmount/common:currency/text()', ns).to_s.should == 'EUR'
      end

      it 'should provide a value' do
        @root_node.xpath('./payment:modificationAmount/common:value/text()', ns).to_s.should == '1000'
      end
    end

    context 'response' do
      it 'should get a refund-received message' do
        @response[:response].should == '[refund-received]'
      end

      it 'should get a new psp reference' do
        @response[:psp_reference].should == '9876543210987654'
      end
    end
  end

  describe "#cancel_or_refund" do
    before(:all) do
      setup_mock_driver(<<EOF)
<?xml version="1.0" encoding="UTF-8"?>
<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
  <soap:Body>
    <ns1:cancelOrRefundResponse xmlns:ns1="http://payment.services.adyen.com">
      <ns1:cancelOrRefundResult>
        <pspReference xmlns="http://payment.services.adyen.com">9876543210987654</pspReference>
        <response xmlns="http://payment.services.adyen.com">[cancelOrRefund-received]</response>
      </ns1:cancelOrRefundResult>
    </ns1:cancelOrRefundResponse>
  </soap:Body>
</soap:Envelope>
EOF

      @response = Adyen::SOAP::PaymentService.cancel_or_refund({
        :merchant_account => 'YourMerchantAccount',
        :original_reference => '1234567890123456'
      })
    end

    context 'request' do
      before(:all) do
        @root_node = get_last_request_body.xpath('//payment:cancelOrRefund/payment:modificationRequest', ns)
      end

      it 'should setup a modificationRequest' do
        @root_node.should_not be_empty
      end

      it 'should provide a merchantAccount' do
        @root_node.xpath('./payment:merchantAccount/text()', ns).to_s.should == 'YourMerchantAccount'
      end

      it 'should provide an originalReference' do
        @root_node.xpath('./payment:originalReference/text()', ns).to_s.should == '1234567890123456'
      end
    end

    context 'response' do
      it 'should get a cancelOrRefund-received message' do
        @response[:response].should == '[cancelOrRefund-received]'
      end

      it 'should get a new psp reference' do
        @response[:psp_reference].should == '9876543210987654'
      end
    end
  end

private

  def setup_mock_driver(content)
    Handsoap::Http.drivers[:mock] = Handsoap::Http::Drivers::MockDriver.new({
      :status => 200,
      :headers => [
        'Date: Sat, 09 Jan 2010 01:14:41 GMT',
        'Server: Apache',
        'Content-Type: text/xml;charset=UTF-8'
      ].join("\r\n"),
      :content => content
    })
    Handsoap.http_driver = :mock
  end

  def get_last_request_body
    Nokogiri::XML::Document.parse(Handsoap::Http.drivers[:mock].last_request.body)
  end

  def ns
    {
      'payment'   => 'http://payment.services.adyen.com',
      'recurring' => 'http://recurring.services.adyen.com',
      'common'    => 'http://common.services.adyen.com'
    }
  end

end
