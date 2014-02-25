# encoding: UTF-8
require 'api/spec_helper'

shared_examples_for "payment requests" do
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

  it "includes the shopper’s details" do
    text('./payment:shopperReference').should == 'user-id'
    text('./payment:shopperEmail').should == 's.hopper@example.com'
    text('./payment:shopperIP').should == '61.294.12.12'
    text('./payment:shopperStatement').should == 'invoice number 123456'
  end

  it "includes the fraud offset" do
    text('./payment:fraudOffset').should == '30'
  end

  it "does not include the fraud offset if none is given" do
    @payment.params.delete(:fraud_offset)
    xpath('./payment:fraudOffset').should be_empty
  end

  it "includes the given amount of `installments'" do
    xpath('./payment:installments') do |amount|
      amount.text('./common:value').should == '6'
    end
  end

  it "does not include the installments amount if none is given" do
    @payment.params.delete(:installments)
    xpath('./payment:installments').should be_empty
  end

  it "only includes shopper details for given parameters" do
    # TODO pretty lame, but for now it will do
    unless @method == "authorise_one_click_payment_request_body" || @method == "authorise_recurring_payment_request_body"
      @payment.params[:shopper].delete(:reference)
      xpath('./payment:shopperReference').should be_empty
      @payment.params[:shopper].delete(:email)
      xpath('./payment:shopperEmail').should be_empty
      @payment.params[:shopper].delete(:ip)
      xpath('./payment:shopperIP').should be_empty
      @payment.params[:shopper].delete(:statement)
      xpath('./payment:shopperStatement').should be_empty
    end
  end

  it "does not include any shopper details if none are given" do
    # TODO pretty lame, but for now it will do
    unless @method == "authorise_one_click_payment_request_body" || @method == "authorise_recurring_payment_request_body"
      @payment.params.delete(:shopper)
      xpath('./payment:shopperReference').should be_empty
      xpath('./payment:shopperEmail').should be_empty
      xpath('./payment:shopperIP').should be_empty
      xpath('./payment:statement').should be_empty
    end
  end
end

shared_examples_for "recurring payment requests" do
  it_should_behave_like "payment requests"

  it "uses the given recurring detail reference" do
    @payment.params[:recurring_detail_reference] = 'RecurringDetailReference1'
    text('./payment:selectedRecurringDetailReference').should == 'RecurringDetailReference1'
  end
end

describe Adyen::API::PaymentService do
  include APISpecHelper

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
        :statement => 'invoice number 123456',
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
      },
      :installments => {
        :value => 6
      },
      :recurring_detail_reference => 'RecurringDetailReference1',
      :fraud_offset => 30
    }
    @payment = @object = Adyen::API::PaymentService.new(@params)
  end

  describe_request_body_of :authorise_payment do
    it_should_behave_like "payment requests"

    it_should_validate_request_parameters :merchant_account,
                                          :reference,
                                          :amount => [:currency, :value],
                                          :card => [:holder_name, :number, :cvc, :expiry_year, :expiry_month]

    it_should_validate_request_param(:shopper) do
      @payment.params[:recurring] = true
      @payment.params[:shopper] = nil
    end

    it_should_validate_request_param(:fraud_offset) do
      @payment.params[:fraud_offset] = ''
    end

    [:reference, :email].each do |attr|
      it_should_validate_request_param(:shopper) do
        @payment.params[:recurring] = true
        @payment.params[:shopper][attr] = ''
      end
    end

    it "includes the creditcard details" do
      xpath('./payment:card') do |card|
        # there's no reason why Nokogiri should escape these characters, but as long as they're correct
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

    it "includes the necessary recurring and one-click contract info if the `:recurring' param is truthful" do
      xpath('./payment:recurring/payment:contract').should be_empty
      @payment.params[:recurring] = true
      text('./payment:recurring/payment:contract').should == 'RECURRING,ONECLICK'
    end
  end

  describe_response_from :authorise_payment, AUTHORISE_RESPONSE do
    it_should_return_params_for_each_xml_backend({
      :psp_reference => '9876543210987654',
      :result_code => 'Authorised',
      :auth_code => '1234',
      :refusal_reason => ''
    })

    describe "with a authorized response" do
      it "returns that the request was authorised" do
        @response.should be_success
        @response.should be_authorized
      end
    end

    describe "with a `declined' response" do
      before do
        stub_net_http(AUTHORISATION_DECLINED_RESPONSE)
        @response = @payment.authorise_payment
      end

      it "returns that the request was not authorised" do
        @response.should_not be_success
        @response.should_not be_authorized
      end
    end

    describe "with a `refused' response" do
      before do
        stub_net_http(AUTHORISE_REQUEST_REFUSED_RESPONSE)
        @response = @payment.authorise_payment
      end

      it "returns that the payment was refused" do
        @response.should be_refused
        @response.error.should == [:base, 'Transaction was refused.']
      end
    end

    describe "with a `invalid' response" do
      before do
        stub_net_http(AUTHORISE_REQUEST_INVALID_RESPONSE % 'validation 101 Invalid card number')
        @response = @payment.authorise_payment
      end

      it "returns that the request was not authorised" do
        @response.should_not be_success
        @response.should_not be_authorized
      end

      it "it returns that the request was invalid" do
        @response.should be_invalid_request
      end

      it "returns the fault message from #refusal_reason" do
        @response.refusal_reason.should == 'validation 101 Invalid card number'
        @response.params[:refusal_reason].should == 'validation 101 Invalid card number'
      end

      it "returns creditcard validation errors" do
        [
          ["validation 101 Invalid card number",                           [:number,       'is not a valid creditcard number']],
          ["validation 103 CVC is not the right length",                   [:cvc,          'is not the right length']],
          ["validation 128 Card Holder Missing",                           [:holder_name,  'can\'t be blank']],
          ["validation Couldn't parse expiry year",                        [:expiry_year,  'could not be recognized']],
          ["validation Expiry month should be between 1 and 12 inclusive", [:expiry_month, 'could not be recognized']],
        ].each do |message, error|
          response_with_fault_message(message).error.should == error
        end
      end

      it "returns any other fault messages on `base'" do
        message = "validation 130 Reference Missing"
        response_with_fault_message(message).error.should == [:base, message]
      end

      it "prepends the error attribute with the given prefix, except for :base" do
        [
          ["validation 101 Invalid card number",            [:card_number, 'is not a valid creditcard number']],
          ["validation 130 Reference Missing",              [:base,        "validation 130 Reference Missing"]],
          ["validation 152 Invalid number of installments", [:base,        "validation 152 Invalid number of installments"]],
        ].each do |message, error|
          response_with_fault_message(message).error(:card).should == error
        end
      end

      private

      def response_with_fault_message(message)
        stub_net_http(AUTHORISE_REQUEST_INVALID_RESPONSE % message)
        @response = @payment.authorise_payment
      end
    end
  end

  describe_request_body_of :authorise_recurring_payment do
    it_should_behave_like "recurring payment requests"

    it_should_validate_request_parameters :merchant_account,
                                          :reference,
                                          :fraud_offset,
                                          :amount  => [:currency, :value],
                                          :shopper => [:reference, :email]

    it "includes the contract type, which is `RECURRING'" do
      text('./payment:recurring/payment:contract').should == 'RECURRING'
    end

    it "uses the latest recurring detail reference, by default" do
      @payment.params[:recurring_detail_reference] = nil
      text('./payment:selectedRecurringDetailReference').should == 'LATEST'
    end

    it "obviously includes the obligatory self-‘describing’ nonsense parameters" do
      text('./payment:shopperInteraction').should == 'ContAuth'
    end

    it "does not include any creditcard details" do
      xpath('./payment:card').should be_empty
    end
  end

  describe_response_from :authorise_recurring_payment, AUTHORISE_RESPONSE do
    it_should_return_params_for_each_xml_backend({
      :psp_reference => '9876543210987654',
      :result_code => 'Authorised',
      :auth_code => '1234',
      :refusal_reason => ''
    })
  end

  describe_request_body_of :authorise_one_click_payment do
    it_should_behave_like "recurring payment requests"

    it_should_validate_request_parameters :merchant_account,
                                          :reference,
                                          :recurring_detail_reference,
                                          :fraud_offset,
                                          :amount  => [:currency, :value],
                                          :shopper => [:reference, :email],
                                          :card    => [:cvc]

    it "includes the contract type, which is `ONECLICK'" do
      text('./payment:recurring/payment:contract').should == 'ONECLICK'
    end

    it "does not include the self-‘describing’ nonsense parameters" do
      xpath('./payment:shopperInteraction').should be_empty
    end

    it "includes only the creditcard's CVC code" do
      xpath('./payment:card') do |card|
        card.text('./payment:cvc').should == '737'

        card.xpath('./payment:holderName').should be_empty
        card.xpath('./payment:number').should be_empty
        card.xpath('./payment:expiryMonth').should be_empty
        card.xpath('./payment:expiryYear').should be_empty
      end
    end
  end

  describe_response_from :authorise_one_click_payment, AUTHORISE_RESPONSE do
    it_should_return_params_for_each_xml_backend({
      :psp_reference => '9876543210987654',
      :result_code => 'Authorised',
      :auth_code => '1234',
      :refusal_reason => ''
    })
  end

  describe_modification_request_body_of :capture do
    it_should_validate_request_parameters :merchant_account,
                                          :psp_reference,
                                          :amount => [:currency, :value]

    it "includes the amount to capture" do
      xpath('./payment:modificationAmount') do |amount|
        amount.text('./common:currency').should == 'EUR'
        amount.text('./common:value').should == '1234'
      end
    end
  end

  describe_response_from :capture, CAPTURE_RESPONSE % '[capture-received]' do
    it_should_return_params_for_each_xml_backend({
      :psp_reference => '8512867956198946',
      :response => '[capture-received]'
    })

    describe "with a successful response" do
      it "returns that the request was received successfully" do
        @response.should be_success
      end
    end

    describe "with a failed response" do
      before do
        stub_net_http(CAPTURE_RESPONSE % 'failed')
        @response = @payment.capture
      end

      it "returns that the request was not received successfully" do
        @response.should_not be_success
      end
    end
  end

  describe_modification_request_body_of :refund do
    it_should_validate_request_parameters :merchant_account,
                                          :psp_reference,
                                          :amount => [:currency, :value]

    it "includes the amount to refund" do
      xpath('./payment:modificationAmount') do |amount|
        amount.text('./common:currency').should == 'EUR'
        amount.text('./common:value').should == '1234'
      end
    end
  end

  describe_response_from :refund, REFUND_RESPONSE % '[refund-received]' do
    it_should_return_params_for_each_xml_backend({
      :psp_reference => '8512865475512126',
      :response => '[refund-received]'
    })

    describe "with a successful response" do
      it "returns that the request was received successfully" do
        @response.should be_success
      end
    end

    describe "with a failed response" do
      before do
        stub_net_http(REFUND_RESPONSE % 'failed')
        @response = @payment.refund
      end

      it "returns that the request was not received successfully" do
        @response.should_not be_success
      end
    end
  end

  describe_modification_request_body_of :cancel_or_refund, 'cancelOrRefund' do
    it_should_validate_request_parameters :merchant_account,
                                          :psp_reference
  end

  describe_response_from :cancel_or_refund, CANCEL_OR_REFUND_RESPONSE % '[cancelOrRefund-received]' do
    it_should_return_params_for_each_xml_backend({
      :psp_reference => '8512865521218306',
      :response => '[cancelOrRefund-received]'
    })

    describe "with a successful response" do
      it "returns that the request was received successfully" do
        @response.should be_success
      end
    end

    describe "with a failed response" do
      before do
        stub_net_http(CANCEL_OR_REFUND_RESPONSE % 'failed')
        @response = @payment.cancel_or_refund
      end

      it "returns that the request was not received successfully" do
        @response.should_not be_success
      end
    end
  end

  describe_modification_request_body_of :cancel do
    it_should_validate_request_parameters :merchant_account,
                                          :psp_reference
  end

  describe_response_from :cancel, CANCEL_RESPONSE % '[cancel-received]' do
    it_should_return_params_for_each_xml_backend({
      :psp_reference => '8612865544848013',
      :response => '[cancel-received]'
    })

    describe "with a successful response" do
      it "returns that the request was received successfully" do
        @response.should be_success
      end
    end

    describe "with a failed response" do
      before do
        stub_net_http(CANCEL_RESPONSE % 'failed')
        @response = @payment.cancel
      end

      it "returns that the request was not received successfully" do
        @response.should_not be_success
      end
    end
  end

  private

  def node_for_current_method
    node_for_current_object_and_method.xpath('//payment:authorise/payment:paymentRequest')
  end
end

