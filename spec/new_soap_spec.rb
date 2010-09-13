require File.expand_path('../spec_helper', __FILE__)
require 'adyen/new_soap'

require 'rubygems'
require 'nokogiri'

module Net
  class HTTP
    class Post
      attr_reader :header
      attr_reader :assigned_basic_auth

      def basic_auth(username, password)
        @assigned_basic_auth = [username, password]
      end
    end

    class << self
      attr_accessor :posted, :stubbed_response

      def reset!
        @posted = nil
        @stubbed_response = nil
      end
    end

    def host
      @address
    end

    def start
      yield self
    end

    def request(request)
      self.class.posted = [self, request]
      self.class.stubbed_response
    end
  end
end

Adyen::SOAP.username = 'SuperShopper'
Adyen::SOAP.password = 'secret'

describe Adyen::SOAP::NewPaymentService do
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
      @payment = Adyen::SOAP::NewPaymentService.new(@params)
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
        select('./payment:amount') do
          text('./common:currency').should == 'EUR'
          text('./common:value').should == '1234'
        end
      end

      it "includes the creditcard details" do
        select('./payment:card') do
          # there's no reason why Nokogiri should escape these characters, but as longs as they're correct
          text('./payment:holderName').should == 'Simon &#x308F;&#x304F;&#x308F;&#x304F; Hopper'
          text('./payment:number').should == '4444333322221111'
          text('./payment:cvc').should == '737'
          text('./payment:expiryMonth').should == '12'
          text('./payment:expiryYear').should == '2012'
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
        select('./payment:shopperReference').should be_empty
        @payment.params[:shopper].delete(:email)
        select('./payment:shopperEmail').should be_empty
        @payment.params[:shopper].delete(:ip)
        select('./payment:shopperIP').should be_empty
      end

      it "does not include any shopper details if none are given" do
        @payment.params.delete(:shopper)
        select('./payment:shopperReference').should be_empty
        select('./payment:shopperEmail').should be_empty
        select('./payment:shopperIP').should be_empty
      end

      it "includes the necessary recurring contract info if the `:recurring' param is truthful" do
        select('./recurring:recurring/payment:contract').should be_empty
        @payment.params[:recurring] = true
        text('./recurring:recurring/payment:contract').should == 'RECURRING'
      end
    end

    describe "authorise_payment" do
      before do
        Net::HTTP.reset!

        response = Net::HTTPOK.new('1.1', '200', 'OK')
        response.stub!(:body).and_return(AUTHORISE_RESPONSE)
        Net::HTTP.stubbed_response = response

        @payment.authorise_payment
        @request, @post = Net::HTTP.posted
      end

      it "posts the body generated for the given parameters" do
        @post.body.should == @payment.authorise_payment_request_body
      end

      it "posts to Adyen::SOAP::NewPaymentService.endpoint" do
        endpoint = Adyen::SOAP::NewPaymentService.endpoint
        @request.host.should == endpoint.host
        @request.port.should == endpoint.port
        @post.path.should == endpoint.path
      end

      it "makes a request over SSL" do
        @request.use_ssl.should == true
      end

      it "verifies certificates" do
        File.should exist(Adyen::SOAP::CACERT)
        @request.ca_file.should == Adyen::SOAP::CACERT
        @request.verify_mode.should == OpenSSL::SSL::VERIFY_PEER
      end

      it "uses basic-authentication with the credentials set on the Adyen::SOAP module" do
        username, password = @post.assigned_basic_auth
        username.should == 'SuperShopper'
        password.should == 'secret'
      end

      it "sends the proper headers" do
        @post.header.should == {
          'accept'       => ['text/xml'],
          'content-type' => ['text/xml; charset=utf-8'],
          'soapaction'   => ['authorise']
        }
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

  NS = {
    'payment'   => 'http://payment.services.adyen.com',
    'recurring' => 'http://recurring.services.adyen.com',
    'common'    => 'http://common.services.adyen.com'
  }

  def root_for_current_method
    doc = Nokogiri::XML::Document.parse(@payment.send(@method))
    doc.xpath('//payment:authorise/payment:paymentRequest', NS)
  end

  def root
    @root || root_for_current_method
  end

  def select(query)
    result = root.xpath(query, NS)
    if block_given?
      before, @root = @root, result
      yield
    end
    result
  ensure
    @root = before if before
  end

  def text(query)
    select("#{query}/text()").to_s
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
