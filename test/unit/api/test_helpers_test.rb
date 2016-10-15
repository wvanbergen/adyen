# encoding: UTF-8

require 'unit/api/test_helper'
require 'adyen/api/test_helpers'

describe "Test helpers" do
  include APISpecHelper

  after do
    Net::HTTP.stubbing_enabled = false
  end

  describe Adyen::API::PaymentService do
    before do
      @params = {
        :reference => 'order-id',
        :amount => {
          :currency => 'EUR',
          :value => '1234',
        },
        :shopper => {
          :email => 's.hopper@example.com',
          :reference => 'user-id',
          :ip => '61.294.12.12',
          :statement => 'Invoice number 123456'
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
      @payment = @object = Adyen::API::PaymentService.new(@params)
    end

    it "returns an `authorized' response" do
      stub_net_http(AUTHORISATION_DECLINED_RESPONSE)
      Adyen::API::PaymentService.stub_success!
      @payment.authorise_payment.must_be :authorized?

      @payment.authorise_payment.wont_be :authorized?
    end

    it "returns a `refused' response" do
      stub_net_http(AUTHORISE_RESPONSE)
      Adyen::API::PaymentService.stub_refused!
      response = @payment.authorise_payment
      response.wont_be :authorized?
      response.wont_be :invalid_request?

      @payment.authorise_payment.must_be :authorized?
    end

    it "returns a `invalid request' response" do
      stub_net_http(AUTHORISE_RESPONSE)
      Adyen::API::PaymentService.stub_invalid!
      response = @payment.authorise_payment
      response.wont_be :authorized?
      response.must_be :invalid_request?

      @payment.authorise_payment.must_be :authorized?
    end
  end

  describe Adyen::API::RecurringService do
    before do
      @params = { :shopper => { :reference => 'user-id' } }
      @recurring = @object = Adyen::API::RecurringService.new(@params)
    end

    it "returns a `disabled' response" do
      stub_net_http(DISABLE_RESPONSE % 'nope')
      Adyen::API::RecurringService.stub_disabled!
      @recurring.disable.must_be :disabled?
      @recurring.disable.wont_be :disabled?
    end
  end
end
