require File.expand_path('../spec_helper', __FILE__)
require 'adyen/api'

require 'rubygems'
require 'nokogiri'

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
          old_basic_auth
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
    def start
      Net::HTTP.stubbing_enabled ? yield(self) : old_start
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
      public :authorise_payment_request_body
    end

    class RecurringService
      public :list_request_body
    end
  end
end

module APISpecHelper
  def node_for_current_method(object)
    node = Adyen::API::XMLQuerier.new(object.send(@method))
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
    response.stub!(:body).and_return(response_body)
    Net::HTTP.stubbed_response = response
  end

  class SOAPClient < Adyen::API::SimpleSOAPClient
    ENDPOINT_URI = 'https://%s.example.com/soap/Action'
  end
end

Adyen::API.default_params = { :merchant_account => 'SuperShopper' }
Adyen::API.username = 'SuperShopper'
Adyen::API.password = 'secret'

describe Adyen::API::SimpleSOAPClient do
  before do
    @client = APISpecHelper::SOAPClient.new(:reference => 'order-id')
  end

  it "returns the endpoint, for the current environment, from the ENDPOINT_URI constant" do
    uri = APISpecHelper::SOAPClient.endpoint
    uri.scheme.should == 'https'
    uri.host.should == 'test.example.com'
    uri.path.should == '/soap/Action'
  end

  it "initializes with the given parameters" do
    @client.params[:reference].should == 'order-id'
  end

  it "merges the default parameters with the given ones" do
    @client.params[:merchant_account].should == 'SuperShopper'
  end

  describe "call_webservice_action" do
    include APISpecHelper

    before do
      stub_net_http(AUTHORISE_RESPONSE)
      @client.call_webservice_action('Action', '<bananas>Yes, please</bananas>')
      @request, @post = Net::HTTP.posted
    end

    after do
      Net::HTTP.stubbing_enabled = false
    end

    it "posts to the class's endpoint" do
      endpoint = APISpecHelper::SOAPClient.endpoint
      @request.host.should == endpoint.host
      @request.port.should == endpoint.port
      @post.path.should == endpoint.path
    end

    it "makes a request over SSL" do
      @request.use_ssl.should == true
    end

    it "verifies certificates" do
      File.should exist(Adyen::API::SimpleSOAPClient::CACERT)
      @request.ca_file.should == Adyen::API::SimpleSOAPClient::CACERT
      @request.verify_mode.should == OpenSSL::SSL::VERIFY_PEER
    end

    it "uses basic-authentication with the credentials set on the Adyen::API module" do
      username, password = @post.assigned_basic_auth
      username.should == 'SuperShopper'
      password.should == 'secret'
    end

    it "sends the proper headers" do
      @post.header.should == {
        'accept'       => ['text/xml'],
        'content-type' => ['text/xml; charset=utf-8'],
        'soapaction'   => ['Action']
      }
    end
  end
end

describe Adyen::API::PaymentService do
  describe "for a normal payment request" do
    before do
      @params = {
        :merchant_account => 'SuperShopper',
        :reference => 'order-id',
        :amount => {
          :currency => 'EUR',
          :value => '1234',
        },
        :shopper => {
          :email => 's.hopper@example.com',
          :reference => 'user-id',
          :ip => '61.294.12.12',
        },
        :card => {
          :expiry_month => 12,
          :expiry_year => 2012,
          :holder_name => 'Simon わくわく Hopper',
          :number => '4444333322221111',
          :cvc => '737',
          # Maestro UK/Solo only
          #:issue_number => ,
          #:start_month => ,
          #:start_year => ,
        }
      }
      @payment = Adyen::API::PaymentService.new(@params)
    end

    describe "authorise_payment_request_body" do
      before :all do
        @method = :authorise_payment_request_body
      end

      it "includes the merchant account handle" do
        text('./payment:merchantAccount').should == 'SuperShopper'
      end

      it "includes the payment reference of the merchant" do
        text('./payment:reference').should == 'order-id'
      end

      it "includes the given amount of `currency'" do
        xpath('./payment:amount') do |amount|
          amount.text('./common:currency').should == 'EUR'
          amount.text('./common:value').should == '1234'
        end
      end

      it "includes the creditcard details" do
        xpath('./payment:card') do |card|
          # there's no reason why Nokogiri should escape these characters, but as longs as they're correct
          card.text('./payment:holderName').should == 'Simon &#x308F;&#x304F;&#x308F;&#x304F; Hopper'
          card.text('./payment:number').should == '4444333322221111'
          card.text('./payment:cvc').should == '737'
          card.text('./payment:expiryMonth').should == '12'
          card.text('./payment:expiryYear').should == '2012'
        end
      end

      it "formats the creditcard’s expiry month as a two digit number" do
        @payment.params[:card][:expiry_month] = 6
        text('./payment:card/payment:expiryMonth').should == '06'
      end

      it "includes the shopper’s details" do
        text('./payment:shopperReference').should == 'user-id'
        text('./payment:shopperEmail').should == 's.hopper@example.com'
        text('./payment:shopperIP').should == '61.294.12.12'
      end

      it "only includes shopper details for given parameters" do
        @payment.params[:shopper].delete(:reference)
        xpath('./payment:shopperReference').should be_empty
        @payment.params[:shopper].delete(:email)
        xpath('./payment:shopperEmail').should be_empty
        @payment.params[:shopper].delete(:ip)
        xpath('./payment:shopperIP').should be_empty
      end

      it "does not include any shopper details if none are given" do
        @payment.params.delete(:shopper)
        xpath('./payment:shopperReference').should be_empty
        xpath('./payment:shopperEmail').should be_empty
        xpath('./payment:shopperIP').should be_empty
      end

      it "includes the necessary recurring contract info if the `:recurring' param is truthful" do
        xpath('./recurring:recurring/payment:contract').should be_empty
        @payment.params[:recurring] = true
        text('./recurring:recurring/payment:contract').should == 'RECURRING'
      end
    end

    describe "authorise_payment" do
      before do
        stub_net_http(AUTHORISE_RESPONSE)
        @payment.authorise_payment
        @request, @post = Net::HTTP.posted
      end

      after do
        Net::HTTP.stubbing_enabled = false
      end

      it "posts the body generated for the given parameters" do
        @post.body.should == @payment.authorise_payment_request_body
      end

      it "posts to the correct SOAP action" do
        @post.soap_action.should == 'authorise'
      end

      it "returns a hash with parsed response details" do
        @payment.authorise_payment.should == {
          :psp_reference => '9876543210987654',
          :result_code => 'Authorised',
          :auth_code => '1234',
          :refusal_reason => ''
        }
      end
    end
  end

  private

  include APISpecHelper

  def node_for_current_method
    super(@payment).xpath('//payment:authorise/payment:paymentRequest')
  end
end

describe Adyen::API::RecurringService do
  before do
    @params = {
      :merchant_account => 'SuperShopper',
      :shopper => { :reference => 'user-id' }
    }
    @recurring = Adyen::API::RecurringService.new(@params)
  end

  describe "list_request_body" do
    before :all do
      @method = :list_request_body
    end

    it "includes the merchant account handle" do
      text('./recurring:merchantAccount').should == 'SuperShopper'
    end

    it "includes the shopper’s reference" do
      text('./recurring:shopperReference').should == 'user-id'
    end

    it "includes the type of contract, which is always `RECURRING'" do
      text('./recurring:recurring/recurring:contract').should == 'RECURRING'
    end
  end

  describe "list" do
    before do
      stub_net_http(LIST_RESPONSE)
      @recurring.list
      @request, @post = Net::HTTP.posted
    end

    after do
      Net::HTTP.stubbing_enabled = false
    end

    it "posts the body generated for the given parameters" do
      @post.body.should == @recurring.list_request_body
    end

    it "posts to the correct SOAP action" do
      @post.soap_action.should == 'listRecurringDetails'
    end

    it "returns a hash with parsed response details" do
      @recurring.list.should == {
        :creation_date => DateTime.parse('2009-10-27T11:26:22.203+01:00'),
        :last_known_shopper_email => 's.hopper@example.com',
        :shopper_reference => 'user-id',
        :details => [
          {
            :card => {
              :expiry_date => Date.new(2012, 12, 31),
              :holder_name => 'S. Hopper',
              :number => '1111'
            },
            :recurring_detail_reference => 'RecurringDetailReference1',
            :variant => 'mc',
            :creation_date => DateTime.parse('2009-10-27T11:50:12.178+01:00')
          },
          {
            :bank => {
              :bank_account_number => '123456789',
              :bank_location_id => 'bank-location-id',
              :bank_name => 'AnyBank',
              :bic => 'BBBBCCLLbbb',
              :country_code => 'NL',
              :iban => 'NL69PSTB0001234567',
              :owner_name => 'S. Hopper'
            },
            :recurring_detail_reference => 'RecurringDetailReference2',
            :variant => 'IDEAL',
            :creation_date => DateTime.parse('2009-10-27T11:26:22.216+01:00')
          },
        ],
      }
    end
  end

  private

  include APISpecHelper

  def node_for_current_method
    super(@recurring).xpath('//recurring:listRecurringDetails/recurring:request')
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
        </details>
        <ns1:lastKnownShopperEmail>s.hopper@example.com</ns1:lastKnownShopperEmail>
        <ns1:shopperReference>user-id</ns1:shopperReference>
      </ns1:result>
    </ns1:listRecurringDetailsResponse>
  </soap:Body>
</soap:Envelope>
EOS
