# encoding: UTF-8
require 'spec_helper'

require 'adyen/api'

require 'rubygems'
require 'nokogiri'
require 'rexml/document'

Adyen.configuration.default_api_params = { :merchant_account => 'SuperShopper' }
Adyen.configuration.api_username = 'SuperShopper'
Adyen.configuration.api_password = 'secret'

module Net
  class HTTP
    class Post
      attr_reader :header
      attr_reader :assigned_basic_auth

      alias old_basic_auth basic_auth
      def basic_auth(username, password)
        if Net::HTTP.stubbing_enabled
          @assigned_basic_auth = [username, password]
        else
          old_basic_auth(username, password)
        end
      end

      def soap_action
        header['soapaction'].first
      end
    end

    class << self
      attr_accessor :stubbing_enabled, :posted, :stubbed_response

      def stubbing_enabled=(enabled)
        reset! if @stubbing_enabled = enabled
      end

      def reset!
        @posted = nil
        @stubbed_response = nil
      end
    end

    def host
      @address
    end

    alias old_start start
    def start(&block)
      Net::HTTP.stubbing_enabled ? yield(self) : old_start(&block)
    end

    alias old_request request
    def request(request)
      if Net::HTTP.stubbing_enabled
        self.class.posted = [self, request]
        self.class.stubbed_response
      else
        old_request(request)
      end
    end
  end
end

module Adyen
  module API
    class PaymentService
      public :authorise_payment_request_body,
             :authorise_recurring_payment_request_body,
             :authorise_one_click_payment_request_body,
             :capture_request_body, :refund_request_body,
             :cancel_or_refund_request_body,
             :cancel_request_body
    end

    class RecurringService
      public :list_request_body, :disable_request_body
    end
  end
end

module APISpecHelper
  def node_for_current_object_and_method
    Adyen::API::XMLQuerier.new(@object.send(@method))
  end

  def xpath(query, &block)
    node_for_current_method.xpath(query, &block)
  end

  def text(query)
    node_for_current_method.text(query)
  end

  def stub_net_http(response_body)
    Net::HTTP.stubbing_enabled = true
    response = Net::HTTPOK.new('1.1', '200', 'OK')
    response.stub(:body).and_return(response_body)
    Net::HTTP.stubbed_response = response
  end

  def self.included(klass)
    klass.extend ClassMethods
  end

  module ClassMethods
    def for_each_xml_backend(&block)
      [:nokogiri, :rexml].each do |xml_backend|
        describe "with a #{xml_backend} backend" do
          before { Adyen::API::XMLQuerier.backend = xml_backend }
          after  { Adyen::API::XMLQuerier.backend = :nokogiri }
          instance_eval(&block)
        end
      end
    end

    def it_should_have_shortcut_methods_for_params_on_the_response
      it "provides shortcut methods, on the response object, for all entries in the #params hash" do
        @response.params.each do |key, value|
          @response.send(key).should == value
        end
      end
    end

    def it_should_return_params_for_each_xml_backend(params)
      for_each_xml_backend do
        it "returns a hash with parsed response details" do
          @object.send(@method).params.should == params
        end
      end
    end

    def it_should_validate_request_parameters(*params)
      params.each do |param|
        case param
        when Symbol
          it_should_validate_request_param(param) { @object.params[param] = '' }
        when Hash
          param.each do |name, attrs|
            it_should_validate_request_param(name) { @object.params[name] = nil }
            attrs.each do |attr|
              it_should_validate_request_param("#{name} => :#{attr}") { @object.params[name][attr] = nil }
            end
          end
        end
      end
    end

    def it_should_validate_request_param(name, &block)
      it "validates the `#{name}' request parameter" do
        instance_eval &block
        lambda { @object.send(@method) }.should raise_error(ArgumentError)
      end
    end

    def describe_response_from(method, response, soap_action = 'authorise', &block)
      describe(method) do
        before do
          stub_net_http(response)
          @method = method
          @object.params.merge!(:psp_reference => '9876543210987654')
          @response = @object.send(@method)
          @request, @post = Net::HTTP.posted
        end

        after do
          Net::HTTP.stubbing_enabled = false
        end

        it "posts the body generated for the given parameters" do
          @post.body.should == Adyen::API::SimpleSOAPClient::ENVELOPE % @object.send("#{@method}_request_body")
        end

        it "posts to the correct SOAP action" do
          @post.soap_action.should == soap_action
        end

        it_should_have_shortcut_methods_for_params_on_the_response

        instance_eval(&block)
      end
    end

    def describe_request_body_of(method, xpath = nil, &block)
      method = "#{method}_request_body"
      describe(method) do
        before { @method = method }
        if xpath
          define_method(:node_for_current_method) do
            node_for_current_object_and_method.xpath(xpath)
          end
        end
        instance_eval(&block)
      end
    end

    def describe_modification_request_body_of(method, camelized_method = nil, &block)
      describe_request_body_of method, "//payment:#{camelized_method || method}/payment:modificationRequest" do
        before do
          @payment.params[:psp_reference] = 'original-psp-reference'
        end

        it "includes the merchant account" do
          text('./payment:merchantAccount').should == 'SuperShopper'
        end

        it "includes the payment (PSP) reference of the payment to refund" do
          text('./payment:originalReference').should == 'original-psp-reference'
        end

        instance_eval(&block) if block_given?
      end
    end
  end
end

AUTHORISE_RESPONSE = <<EOS
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
EOS

AUTHORISATION_DECLINED_RESPONSE = <<EOS
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
        <refusalReason xmlns="http://payment.services.adyen.com">You need to actually own money.</refusalReason>
        <resultCode xmlns="http://payment.services.adyen.com">Refused</resultCode>
      </ns1:paymentResult>
    </ns1:authoriseResponse>
  </soap:Body>
</soap:Envelope>
EOS

AUTHORISE_REQUEST_INVALID_RESPONSE = <<EOS
<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
  <soap:Body>
    <soap:Fault>
      <faultcode>soap:Server</faultcode>
      <faultstring>%s</faultstring>
    </soap:Fault>
  </soap:Body>
</soap:Envelope>
EOS

AUTHORISE_REQUEST_REFUSED_RESPONSE = <<EOS
<?xml version="1.0" encoding="UTF-8"?>
<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
  <soap:Body>
    <ns1:authoriseResponse xmlns:ns1="http://payment.services.adyen.com">
      <ns1:paymentResult>
        <refusalReason xmlns="http://payment.services.adyen.com">You need to actually own money.</refusalReason>
        <resultCode xmlns="http://payment.services.adyen.com">Refused</resultCode>
      </ns1:paymentResult>
    </ns1:authoriseResponse>
  </soap:Body>
</soap:Envelope>
EOS


LIST_RESPONSE = <<EOS
<?xml version="1.0"?>
<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
  <soap:Body>
    <ns1:listRecurringDetailsResponse xmlns:ns1="http://recurring.services.adyen.com">
      <ns1:result xmlns:ns2="http://payment.services.adyen.com">
        <ns1:creationDate>2009-10-27T11:26:22.203+01:00</ns1:creationDate>
        <details xmlns="http://recurring.services.adyen.com">
          <RecurringDetail>
            <bank xsi:nil="true"/>
            <card>
              <cvc xmlns="http://payment.services.adyen.com" xsi:nil="true"/>
              <expiryMonth xmlns="http://payment.services.adyen.com">12</expiryMonth>
              <expiryYear xmlns="http://payment.services.adyen.com">2012</expiryYear>
              <holderName xmlns="http://payment.services.adyen.com">S. Hopper</holderName>
              <issueNumber xmlns="http://payment.services.adyen.com" xsi:nil="true"/>
              <number xmlns="http://payment.services.adyen.com">1111</number>
              <startMonth xmlns="http://payment.services.adyen.com" xsi:nil="true"/>
              <startYear xmlns="http://payment.services.adyen.com" xsi:nil="true"/>
            </card>
            <creationDate>2009-10-27T11:50:12.178+01:00</creationDate>
            <elv xsi:nil="true"/>
            <name/>
            <recurringDetailReference>RecurringDetailReference1</recurringDetailReference>
            <variant>mc</variant>
          </RecurringDetail>
          <RecurringDetail>
            <bank>
              <bankAccountNumber xmlns="http://payment.services.adyen.com">123456789</bankAccountNumber>
              <bankLocationId xmlns="http://payment.services.adyen.com">bank-location-id</bankLocationId>
              <bankName xmlns="http://payment.services.adyen.com">AnyBank</bankName>
              <bic xmlns="http://payment.services.adyen.com">BBBBCCLLbbb</bic>
              <countryCode xmlns="http://payment.services.adyen.com">NL</countryCode>
              <iban xmlns="http://payment.services.adyen.com">NL69PSTB0001234567</iban>
              <ownerName xmlns="http://payment.services.adyen.com">S. Hopper</ownerName>
            </bank>
            <card xsi:nil="true"/>
            <creationDate>2009-10-27T11:26:22.216+01:00</creationDate>
            <elv xsi:nil="true"/>
            <name/>
            <recurringDetailReference>RecurringDetailReference2</recurringDetailReference>
            <variant>IDEAL</variant>
          </RecurringDetail>
          <RecurringDetail>
            <card xsi:nil="true"/>
            <bank xsi:nil="true"/>            
            <elv>
              <accountHolderName xmlns="http://payment.services.adyen.com">S. Hopper</accountHolderName>
              <bankAccountNumber xmlns="http://payment.services.adyen.com">1234567890</bankAccountNumber>
              <bankLocation xmlns="http://payment.services.adyen.com">Berlin</bankLocation>
              <bankLocationId xmlns="http://payment.services.adyen.com">12345678</bankLocationId>
              <bankName xmlns="http://payment.services.adyen.com">TestBank</bankName>
            </elv>
            <creationDate>2009-10-27T11:26:22.216+01:00</creationDate>
            <name/>
            <recurringDetailReference>RecurringDetailReference3</recurringDetailReference>
            <variant>elv</variant>
          </RecurringDetail>
        </details>
        <ns1:lastKnownShopperEmail>s.hopper@example.com</ns1:lastKnownShopperEmail>
        <ns1:shopperReference>user-id</ns1:shopperReference>
      </ns1:result>
    </ns1:listRecurringDetailsResponse>
  </soap:Body>
</soap:Envelope>
EOS

LIST_EMPTY_RESPONSE = <<EOS
<?xml version="1.0"?>
<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
  <soap:Body>
    <ns1:listRecurringDetailsResponse xmlns:ns1="http://recurring.services.adyen.com">
      <ns1:result>
        <details xmlns="http://recurring.services.adyen.com"/>
        <lastKnownShopperEmail xmlns="http://recurring.services.adyen.com" xsi:nil="true"/>
        <shopperReference xmlns="http://recurring.services.adyen.com" xsi:nil="true"/>
      </ns1:result>
    </ns1:listRecurringDetailsResponse>
  </soap:Body>
</soap:Envelope>
EOS

DISABLE_RESPONSE = <<EOS
<?xml version="1.0"?>
<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
  <soap:Body>
    <ns1:disableResponse xmlns:ns1="http://recurring.services.adyen.com">
      <ns1:result>
        <response xmlns="http://recurring.services.adyen.com">
          %s
        </response>
      </ns1:result>
    </ns1:disableResponse>
  </soap:Body>
</soap:Envelope>
EOS

REFUND_RESPONSE = <<EOS
<?xml version="1.0"?>
<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
  <soap:Body>
    <ns1:refundResponse xmlns:ns1="http://payment.services.adyen.com">
      <ns1:refundResult>
        <additionalData xmlns="http://payment.services.adyen.com" xsi:nil="true"/>
        <pspReference xmlns="http://payment.services.adyen.com">8512865475512126</pspReference>
        <response xmlns="http://payment.services.adyen.com">%s</response>
      </ns1:refundResult>
    </ns1:refundResponse>
  </soap:Body>
</soap:Envelope>
EOS

CANCEL_OR_REFUND_RESPONSE = <<EOS
<?xml version="1.0"?>
<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
  <soap:Body>
    <ns1:cancelOrRefundResponse xmlns:ns1="http://payment.services.adyen.com">
      <ns1:cancelOrRefundResult>
        <additionalData xmlns="http://payment.services.adyen.com" xsi:nil="true"/>
        <pspReference xmlns="http://payment.services.adyen.com">8512865521218306</pspReference>
        <response xmlns="http://payment.services.adyen.com">%s</response>
      </ns1:cancelOrRefundResult>
    </ns1:cancelOrRefundResponse>
  </soap:Body>
</soap:Envelope>
EOS

CANCEL_RESPONSE = <<EOS
<?xml version="1.0"?>
<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
  <soap:Body>
    <ns1:cancelResponse xmlns:ns1="http://payment.services.adyen.com">
      <ns1:cancelResult>
        <additionalData xmlns="http://payment.services.adyen.com" xsi:nil="true"/>
        <pspReference xmlns="http://payment.services.adyen.com">8612865544848013</pspReference>
        <response xmlns="http://payment.services.adyen.com">%s</response>
      </ns1:cancelResult>
    </ns1:cancelResponse>
  </soap:Body>
</soap:Envelope>
EOS

CAPTURE_RESPONSE = <<EOS
<?xml version="1.0"?>
<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
  <soap:Body>
    <ns1:captureResponse xmlns:ns1="http://payment.services.adyen.com">
      <ns1:captureResult>
        <additionalData xmlns="http://payment.services.adyen.com" xsi:nil="true"/>
        <pspReference xmlns="http://payment.services.adyen.com">8512867956198946</pspReference>
        <response xmlns="http://payment.services.adyen.com">%s</response>
      </ns1:captureResult>
    </ns1:captureResponse>
  </soap:Body>
</soap:Envelope>
EOS
