require File.expand_path("../../spec_helper", __FILE__)

require 'rubygems'
require 'nokogiri'

API_SPEC_INITIALIZER = File.expand_path("../initializer.rb", __FILE__)

if File.exist?(API_SPEC_INITIALIZER)

  describe Adyen::API do
    before :all do
      require API_SPEC_INITIALIZER
      @order_id = @user_id = Time.now.to_i
      perform_payment_request
    end

    def perform_payment_request
      @payment_response = Adyen::API.authorise_payment({
        :reference => @order_id,
        :recurring => true,
        :amount => {
          :currency => 'EUR',
          :value => '1234',
        },
        :shopper => {
          :email => "#{@user_id}@example.com",
          :reference => @user_id
        },
        :card => {
          :expiry_month => 12,
          :expiry_year => 2012,
          :holder_name => "Simon #{@user_id} Hopper",
          :number => '4444333322221111',
          :cvc => '737',
          # Maestro UK/Solo only
          #:issue_number => ,
          #:start_month => ,
          #:start_year => ,
        }
      })
    end

    it "performs a payment request" do
      @payment_response.should be_authorized
      @payment_response.psp_reference.should_not be_empty
    end

    it "performs a recurring payment request" do
      response = Adyen::API.authorise_recurring_payment({
        :reference => @order_id,
        :amount => {
          :currency => 'EUR',
          :value => '1234',
        },
        :shopper => {
          :email => "#{@user_id}@example.com",
          :reference => @user_id
        }
      })
      response.should be_authorized
      response.psp_reference.should_not be_empty
    end

    it "captures a payment" do
      response = Adyen::API.capture_payment(@payment_response.psp_reference, 'EUR', '1234')
      response.should be_success
    end

    it "refunds a payment" do
      response = Adyen::API.refund_payment(@payment_response.psp_reference, 'EUR', '1234')
      response.should be_success
    end

    it "cancels or refunds a payment" do
      response = Adyen::API.cancel_or_refund_payment(@payment_response.psp_reference)
      response.should be_success
    end

    it "cancels a payment" do
      response = Adyen::API.cancel_payment(@payment_response.psp_reference)
      response.should be_success
    end

    it "disables a recurring contract" do
      response = Adyen::API.disable_recurring_contract(@user_id)
      response.should be_success
      response.should be_disabled
    end
  end

else
  puts "[!] To run the functional tests you'll need to create `spec/functional/initializer.rb' and configure with your test account settings. See `spec/functional/initializer.rb.sample'."
end
