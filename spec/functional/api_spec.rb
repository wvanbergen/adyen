# encoding: UTF-8
require 'api/spec_helper'
require 'nokogiri'

API_SPEC_INITIALIZER = File.expand_path("../initializer.rb", __FILE__)

if File.exist?(API_SPEC_INITIALIZER)

  describe Adyen::API, "with an actual remote connection" do

    before :all do
      require API_SPEC_INITIALIZER
      Net::HTTP.stubbing_enabled = false
      @order_id = @user_id = Time.now.to_i
      @payment_response = perform_payment_request
    end

    after :all do
      Net::HTTP.stubbing_enabled = true
    end

    it "performs a payment request" do
      @payment_response.should be_authorized
      @payment_response.psp_reference.should_not be_empty
    end

    def perform_payment_request
      Adyen::API.authorise_payment(
        @order_id,
        { :currency => 'EUR', :value => '1234' },
        { :email => "#{@user_id}@example.com", :reference => @user_id },
        { :expiry_month => '08', :expiry_year => '2018', :holder_name => "Simon #{@user_id} Hopper", :number => '4111111111111111', :cvc => '737' },
        true
      )
    end

    it "performs a recurring payment request" do
      response = Adyen::API.authorise_recurring_payment(
        @order_id,
        { :currency => 'EUR', :value => '1234' },
        { :email => "#{@user_id}@example.com", :reference => @user_id }
      )
      response.should be_authorized
      response.psp_reference.should_not be_empty
    end

    it "performs a one-click payment request" do
      detail   = Adyen::API.list_recurring_details(@user_id).references.last
      response = Adyen::API.authorise_one_click_payment(
        @order_id,
        { :currency => 'EUR', :value => '1234', :installments => 3 },
        { :email => "#{@user_id}@example.com", :reference => @user_id },
        { :cvc => '737' },
        detail
      )
      response.should be_authorized
      response.psp_reference.should_not be_empty
    end

    it "stores the provided ELV account details" do
      response = Adyen::API.store_recurring_token(
        { :email => "#{@user_id}@example.com", :reference => @user_id },
        { :bank_location => "Berlin", :bank_name => "TestBank", :bank_location_id => "12345678", :holder_name => "Simon #{@user_id} Hopper", :number => "1234567890" }
      )
      response.should be_stored
      response.recurring_detail_reference.should_not be_empty
    end

    it "stores the provided creditcard details" do
      response = Adyen::API.store_recurring_token(
        { :email => "#{@user_id}@example.com", :reference => @user_id },
        { :expiry_month => '08', :expiry_year => '2018', :holder_name => "Simon #{@user_id} Hopper", :number => '4111111111111111' }
      )
      response.should be_stored
      response.recurring_detail_reference.should_not be_empty
    end

    it "disables a recurring contract" do
      response = Adyen::API.disable_recurring_contract(@user_id)
      response.should be_success
      response.should be_disabled
    end

    it "captures a payment" do
      response = Adyen::API.capture_payment(@payment_response.psp_reference, { :currency => 'EUR', :value => '1234' })
      response.should be_success
    end

    it "refunds a payment" do
      response = Adyen::API.refund_payment(@payment_response.psp_reference, { :currency => 'EUR', :value => '1234' })
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

    it "generates a billet" do
      response = Adyen::API.generate_billet("{\"user_id\":66722,\"order_id\":6863}#signup",
                                            { currency: "BRL", value: 1000 },
                                            { first_name: "Jow", last_name: "Silver" },
                                            "19762003691",
                                            "boletobancario_santander",
                                            "2014-07-16T18:16:11Z")
      response.should be_success
    end
  end

else
  puts "[!] To run the functional tests you'll need to create `spec/functional/initializer.rb' and configure with your test account settings. See `spec/functional/initializer.rb.sample'."
end
