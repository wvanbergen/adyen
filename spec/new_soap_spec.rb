require File.expand_path('../spec_helper', __FILE__)
require 'adyen/new_soap'

require 'rubygems'
require 'nokogiri'

describe Adyen::SOAP::NewPaymentService do
  describe "for a normal payment request" do
    before :all do
      @params = {
        :merchant_account => 'YourMerchantAccount',
        :reference => 'order-id',
        :amount => {
          :currency => 'EUR',
          :value => '1234',
        },
        :shopper => {
          :email => 's.hopper@example.com',
          :reference => 'user-id',
        },
        :card => {
          :expiry_month => 6,
          :expiry_year => 2012,
          :holder_name => 'Simon Hopper',
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
        request_body = @payment.authorise_payment_request_body
        @root = parse_request_body(request_body)
        @root = xpath('//payment:authorise/payment:paymentRequest')
      end

      it "includes the given amount of `currency'" do
        text('./payment:amount/common:currency').should == 'EUR'
        text('./payment:amount/common:value').should == '1234'
      end
    end
  end

  private

  NS = {
    'payment'   => 'http://payment.services.adyen.com',
    'recurring' => 'http://recurring.services.adyen.com',
    'common'    => 'http://common.services.adyen.com'
  }

  def parse_request_body(request_body)
    Nokogiri::XML::Document.parse(request_body)
  end

  def xpath(query)
    @root.xpath(query, NS)
  end

  def text(query)
    xpath("#{query}/text()").to_s
  end
end
