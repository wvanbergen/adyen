# encoding: UTF-8
require 'unit/api/test_helper'

module SharedExamples
  def it_behaves_like_a_payment_request
    it "includes the merchant account handle" do
      text('./payment:merchantAccount').must_equal 'SuperShopper'
    end

    it "includes the payment reference of the merchant" do
      text('./payment:reference').must_equal 'order-id'
    end

    it "includes the given amount of `currency'" do
      xpath('./payment:amount') do |amount|
        amount.text('./common:currency').must_equal 'EUR'
        amount.text('./common:value').must_equal '1234'
      end
    end

    it "includes the shopper's details" do
      text('./payment:shopperReference').must_equal 'user-id'
      text('./payment:shopperEmail').must_equal 's.hopper@example.com'
      text('./payment:shopperIP').must_equal '61.294.12.12'
      text('./payment:shopperStatement').must_equal 'invoice number 123456'
    end

    it "includes the fraud offset" do
      text('./payment:fraudOffset').must_equal '30'
    end

    it "does not include the fraud offset if none is given" do
      @payment.params.delete(:fraud_offset)
      xpath('./payment:fraudOffset').must_be :empty?
    end

    it "includes the given amount of `installments'" do
      xpath('./payment:installments') do |amount|
        amount.text('./common:value').must_equal '6'
      end
    end

    it "does not include the installments amount if none is given" do
      @payment.params.delete(:installments)
      xpath('./payment:installments').must_be :empty?
    end

    it "does not includes shopper reference if none set" do
      # TODO pretty lame, but for now it will do
      unless @method == "authorise_one_click_payment_request_body" || @method == "authorise_recurring_payment_request_body"
        @payment.params[:shopper].delete(:reference)
        xpath('./payment:shopperReference').must_be :empty?
      end
    end

    it "does not include shopper email if none given" do
      # TODO pretty lame, but for now it will do
      unless @method == "authorise_one_click_payment_request_body" || @method == "authorise_recurring_payment_request_body"
        @payment.params[:shopper].delete(:email)
        xpath('./payment:shopperEmail').must_be :empty?
      end
    end

    it "does not include shopper IP if none given" do
      # TODO pretty lame, but for now it will do
      unless @method == "authorise_one_click_payment_request_body" || @method == "authorise_recurring_payment_request_body"
        @payment.params[:shopper].delete(:ip)
        xpath('./payment:shopperIP').must_be :empty?
      end
    end

    it "does not include shopper statement if none given" do
      # TODO pretty lame, but for now it will do
      unless @method == "authorise_one_click_payment_request_body" || @method == "authorise_recurring_payment_request_body"
        @payment.params[:shopper].delete(:statement)
        xpath('./payment:shopperStatement').must_be :empty?
      end
    end

    it "does not include any shopper details if none are given" do
      # TODO pretty lame, but for now it will do
      unless @method == "authorise_one_click_payment_request_body" || @method == "authorise_recurring_payment_request_body"
        @payment.params.delete(:shopper)
        xpath('./payment:shopperReference').must_be :empty?
        xpath('./payment:shopperEmail').must_be :empty?
        xpath('./payment:shopperIP').must_be :empty?
        xpath('./payment:statement').must_be :empty?
      end
    end
  end

  def it_behaves_like_a_recurring_payment_request
    it_behaves_like_a_payment_request

    it "uses the given recurring detail reference" do
      @payment.params[:recurring_detail_reference] = 'RecurringDetailReference1'
      text('./payment:selectedRecurringDetailReference').must_equal 'RecurringDetailReference1'
    end
  end
end

describe Adyen::API::PaymentService do
  include APISpecHelper
  extend SharedExamples

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
    it_behaves_like_a_payment_request

    it_should_validate_request_parameters :merchant_account,
                                          :reference,
                                          :amount => [:currency, :value],
                                          :card => [:holder_name, :number, :expiry_year, :expiry_month]

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
        card.text('./payment:holderName').must_equal 'Simon わくわく Hopper'
        card.text('./payment:number').must_equal '4444333322221111'
        card.text('./payment:cvc').must_equal '737'
        card.text('./payment:expiryMonth').must_equal '12'
        card.text('./payment:expiryYear').must_equal '2012'
      end
    end

    it "formats the creditcard's expiry month as a two digit number" do
      @payment.params[:card][:expiry_month] = 6
      text('./payment:card/payment:expiryMonth').must_equal '06'
    end

    it "does not include recurring and one-click contract info if the `:recurring' param is false" do
      xpath('./payment:recurring/payment:contract').must_be :empty?
    end

    it "includes the necessary recurring and one-click contract info if the `:recurring' param is truthful" do
      @payment.params[:recurring] = true
      text('./payment:recurring/payment:contract').must_equal 'RECURRING,ONECLICK'
    end
  end

  describe_response_from :generate_billet, BILLET_RECEIVED_RESPONSE do
    it_should_return_params_for_each_xml_backend({
      :psp_reference => "8814038837489129",
      :result_code => "Received",
      :billet_url => "https://test.adyen.com/hpp/generationBoleto.shtml?data=AgABAQBdYDe9OqdseA79Rfexm2Lz8fRQ1bWqkLhBCf1fHhQEif7bsRKi0otq%2B1ekMAdMIZUiVXeR3QFrAOA8Zy4tpiNLhkMq6f7W2zFqYhVWrByqxQnbQTYuX2FWI7tsu7Vb0MnyOvFfFdFtaxzImZYCli%2BMrqaAJ5HI9ap3egeqBQIsRI%2Fj0zWsu2EGN16lGbwFOLyxl%2By0Pc5jazTo8rnBA7OVPGDIu7Qt%2F2DYIMcB6PXou5W3aJoTC4SldhNdobVqgWUtES8NsWdOYbLGa6I%2BjSwEFXvxyTXwtw4J2E%2BE7ux1UhBiZRj66lMbcvaYlfnR2xWbA%2BKmdLrVvuXTroEHKQ%2B1C%2FuyGuiOk3SmGq6TMgOyCEt%2BmG%2Bq6z5jDi%2BnYLtlLQU4ccMOujgWMfGkViC%2FXDUlqYjKbn8NHwPwoPcelpf1zCDCe%2Fvu6NBTVQbEXbE0oV0j2MT1tLlMdf08iUsDThuQ3MlJbE8VbTMlttOFqoyXhBjepQ42C1eXfswSz1gsZlHanBCTiw1pB69vkvfWPf5IdUSx1cpEr9LJ9PSz%2FeHxEhq%2B8ZdWzrybXqRbEl2mUjLeyhMNuiE%3D"
    })

    describe "with a received billet" do
      it "returns that the request was successful" do
        @response.must_be :success?
      end
    end
  end

  describe_response_from :generate_billet, BILLET_REFUSED_RESPONSE do
    it_should_return_params_for_each_xml_backend({
      :psp_reference => "8514038928235061",
      :result_code => "Refused",
      :billet_url => ""
    })

    describe "with a received billet" do
      it "returns that the request was successful" do
        @response.wont_be :success?
      end
    end
  end

  describe_response_from :authorise_payment, AUTHORISE_RESPONSE do
    it_should_return_params_for_each_xml_backend({
      :psp_reference => '9876543210987654',
      :result_code => 'Authorised',
      :auth_code => '1234',
      :additional_data => { "cardSummary" => "1111" },
      :refusal_reason => ''
    })

    describe "with a authorized response" do
      it "returns that the request was authorised" do
        @response.must_be :success?
        @response.must_be :authorized?
      end
    end

    describe "with a `declined' response" do
      before do
        stub_net_http(AUTHORISATION_DECLINED_RESPONSE)
        @response = @payment.authorise_payment
      end

      it "returns that the request was not authorised" do
        @response.wont_be :success?
        @response.wont_be :authorized?
      end
    end

    describe "with a `refused' response" do
      before do
        stub_net_http(AUTHORISE_REQUEST_REFUSED_RESPONSE)
        @response = @payment.authorise_payment
      end

      it "returns that the payment was refused" do
        @response.must_be :refused?
        @response.error.must_equal [:base, 'Transaction was refused.']
      end
    end

    describe "with a `invalid' response" do
      before do
        stub_net_http(AUTHORISE_REQUEST_INVALID_RESPONSE % 'validation 101 Invalid card number')
        @response = @payment.authorise_payment
      end

      it "returns that the request was not authorised" do
        @response.wont_be :success?
        @response.wont_be :authorized?
      end

      it "it returns that the request was invalid" do
        @response.must_be :invalid_request?
      end

      it "returns the fault message from #refusal_reason" do
        @response.refusal_reason.must_equal 'validation 101 Invalid card number'
        @response.params[:refusal_reason].must_equal 'validation 101 Invalid card number'
      end

      it "returns creditcard validation errors" do
        [
          ["validation 101 Invalid card number",                           [:number,       'is not a valid creditcard number']],
          ["validation 103 CVC is not the right length",                   [:cvc,          'is not the right length']],
          ["validation 128 Card Holder Missing",                           [:holder_name,  'can\'t be blank']],
          ["validation Couldn't parse expiry year",                        [:expiry_year,  'could not be recognized']],
          ["validation Expiry month should be between 1 and 12 inclusive", [:expiry_month, 'could not be recognized']],
        ].each do |message, error|
          response_with_fault_message(message).error.must_equal error
        end
      end

      it "returns any other fault messages on `base'" do
        message = "validation 130 Reference Missing"
        response_with_fault_message(message).error.must_equal [:base, message]
      end

      it "prepends the error attribute with the given prefix, except for :base" do
        [
          ["validation 101 Invalid card number",            [:card_number, 'is not a valid creditcard number']],
          ["validation 130 Reference Missing",              [:base,        "validation 130 Reference Missing"]],
          ["validation 152 Invalid number of installments", [:base,        "validation 152 Invalid number of installments"]],
        ].each do |message, error|
          response_with_fault_message(message).error(:card).must_equal error
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
    it_behaves_like_a_recurring_payment_request

    it_should_validate_request_parameters :merchant_account,
                                          :reference,
                                          :fraud_offset,
                                          :amount  => [:currency, :value],
                                          :shopper => [:reference, :email]

    it "includes the contract type, which is `RECURRING'" do
      text('./payment:recurring/payment:contract').must_equal 'RECURRING'
    end

    it "uses the latest recurring detail reference, by default" do
      @payment.params[:recurring_detail_reference] = nil
      text('./payment:selectedRecurringDetailReference').must_equal 'LATEST'
    end

    it "obviously includes the obligatory self-'describing' nonsense parameters" do
      text('./payment:shopperInteraction').must_equal 'ContAuth'
    end

    it "does not include any creditcard details" do
      xpath('./payment:card').must_be :empty?
    end
  end

  describe_response_from :authorise_recurring_payment, AUTHORISE_RESPONSE do
    it_should_return_params_for_each_xml_backend({
      :psp_reference => '9876543210987654',
      :result_code => 'Authorised',
      :auth_code => '1234',
      :additional_data => { "cardSummary" => "1111" },
      :refusal_reason => ''
    })
  end

  describe_request_body_of :authorise_one_click_payment do
    it_behaves_like_a_recurring_payment_request

    it_should_validate_request_parameters :merchant_account,
                                          :reference,
                                          :recurring_detail_reference,
                                          :fraud_offset,
                                          :amount  => [:currency, :value],
                                          :shopper => [:reference, :email],
                                          :card    => [:cvc]

    it "includes the contract type, which is `ONECLICK'" do
      text('./payment:recurring/payment:contract').must_equal 'ONECLICK'
    end

    it "does not include the self-'describing' nonsense parameters" do
      xpath('./payment:shopperInteraction').must_be :empty?
    end

    it "includes only the creditcard's CVC code" do
      xpath('./payment:card') do |card|
        card.text('./payment:cvc').must_equal '737'

        card.xpath('./payment:holderName').must_be :empty?
        card.xpath('./payment:number').must_be :empty?
        card.xpath('./payment:expiryMonth').must_be :empty?
        card.xpath('./payment:expiryYear').must_be :empty?
      end
    end
  end

  describe_response_from :authorise_one_click_payment, AUTHORISE_RESPONSE do
    it_should_return_params_for_each_xml_backend({
      :psp_reference => '9876543210987654',
      :result_code => 'Authorised',
      :auth_code => '1234',
      :additional_data => { "cardSummary" => "1111" },
      :refusal_reason => ''
    })
  end

  describe_modification_request_body_of :capture do
    it_should_validate_request_parameters :merchant_account,
                                          :psp_reference,
                                          :amount => [:currency, :value]

    it "includes the amount to capture" do
      xpath('./payment:modificationAmount') do |amount|
        amount.text('./common:currency').must_equal 'EUR'
        amount.text('./common:value').must_equal '1234'
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
        @response.must_be :success?
      end
    end

    describe "with a failed response" do
      before do
        stub_net_http(CAPTURE_RESPONSE % 'failed')
        @response = @payment.capture
      end

      it "returns that the request was not received successfully" do
        @response.wont_be :success?
      end
    end
  end

  describe_modification_request_body_of :refund do
    it_should_validate_request_parameters :merchant_account,
                                          :psp_reference,
                                          :amount => [:currency, :value]

    it "includes the amount to refund" do
      xpath('./payment:modificationAmount') do |amount|
        amount.text('./common:currency').must_equal 'EUR'
        amount.text('./common:value').must_equal '1234'
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
        @response.must_be :success?
      end
    end

    describe "with a failed response" do
      before do
        stub_net_http(REFUND_RESPONSE % 'failed')
        @response = @payment.refund
      end

      it "returns that the request was not received successfully" do
        @response.wont_be :success?
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
        @response.must_be :success?
      end
    end

    describe "with a failed response" do
      before do
        stub_net_http(CANCEL_OR_REFUND_RESPONSE % 'failed')
        @response = @payment.cancel_or_refund
      end

      it "returns that the request was not received successfully" do
        @response.wont_be :success?
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
        @response.must_be :success?
      end
    end

    describe "with a failed response" do
      before do
        stub_net_http(CANCEL_RESPONSE % 'failed')
        @response = @payment.cancel
      end

      it "returns that the request was not received successfully" do
        @response.wont_be :success?
      end
    end
  end

  private

  def node_for_current_method
    node_for_current_object_and_method.xpath('//payment:authorise/payment:paymentRequest')
  end
end

