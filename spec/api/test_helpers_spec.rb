# encoding: UTF-8

require 'api/spec_helper'
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
          :statement => 'shopper statement'
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
      @payment.authorise_payment.should be_authorized

      @payment.authorise_payment.should_not be_authorized
    end

    it "returns a `refused' response" do
      stub_net_http(AUTHORISE_RESPONSE)
      Adyen::API::PaymentService.stub_refused!
      response = @payment.authorise_payment
      response.should_not be_authorized
      response.should_not be_invalid_request

      @payment.authorise_payment.should be_authorized
    end

    it "returns a `invalid request' response" do
      stub_net_http(AUTHORISE_RESPONSE)
      Adyen::API::PaymentService.stub_invalid!
      response = @payment.authorise_payment
      response.should_not be_authorized
      response.should be_invalid_request

      @payment.authorise_payment.should be_authorized
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
      @recurring.disable.should be_disabled
      @recurring.disable.should_not be_disabled
    end
  end
end
