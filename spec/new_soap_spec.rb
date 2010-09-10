require File.expand_path('../spec_helper', __FILE__)
require 'adyen/new_soap'

require 'rubygems'
require 'nokogiri'

describe Adyen::SOAP::NewPaymentService do
  describe "for a normal payment request" do
    before do
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
