require 'adyen/api/simple_soap_client'
require 'adyen/api/templates/payment_service'

module Adyen
  module API
    # This is the class that maps actions to Adyen’s Payment SOAP service.
    #
    # It’s encouraged to use the shortcut methods on the {API} module, which abstracts away the
    # difference between this service and the {RecurringService}. Henceforth, for extensive
    # documentation you should look at the {API} documentation.
    #
    # The most important difference is that you instantiate a {PaymentService} with the parameters
    # that are needed for the call that you will eventually make.
    #
    # @example
    #  payment = Adyen::API::PaymentService.new({
    #    :reference => invoice.id,
    #    :amount => {
    #      :currency => 'EUR',
    #      :value => invoice.amount,
    #    },
    #    :shopper => {
    #      :email => user.email,
    #      :reference => user.id,
    #      :ip => request.ip,
    #      :statement => 'Invoice number 123456'
    #    },
    #    :card => {
    #      :expiry_month => 12,
    #      :expiry_year => 2012,
    #      :holder_name => 'Simon Hopper',
    #      :number => '4444333322221111',
    #      :cvc => '737'
    #    }
    #  })
    #  response = payment.authorise_payment
    #  response.authorised? # => true
    #
    class PaymentService < SimpleSOAPClient
      # The Adyen Payment SOAP service endpoint uri.
      ENDPOINT_URI = 'https://pal-%s.adyen.com/pal/servlet/soap/Payment'

      # @see API.authorise_payment
      def authorise_payment
        make_payment_request(authorise_payment_request_body, AuthorisationResponse)
      end

      # @see API.authorise_recurring_payment
      def authorise_recurring_payment
        make_payment_request(authorise_recurring_payment_request_body, AuthorisationResponse)
      end

      # @see API.authorise_one_click_payment
      def authorise_one_click_payment
        make_payment_request(authorise_one_click_payment_request_body, AuthorisationResponse)
      end

      # @see API.capture_payment
      def capture
        make_payment_request(capture_request_body, CaptureResponse)
      end

      # @see API.refund_payment
      def refund
        make_payment_request(refund_request_body, RefundResponse)
      end

      # @see API.cancel_payment
      def cancel
        make_payment_request(cancel_request_body, CancelResponse)
      end

      # @see API.cancel_or_refund_payment
      def cancel_or_refund
        make_payment_request(cancel_or_refund_request_body, CancelOrRefundResponse)
      end

      private

      def make_payment_request(data, response_class)
        call_webservice_action('authorise', data, response_class)
      end

      def authorise_payment_request_body
        content = card_partial
        if @params[:recurring]
          validate_parameters!(:shopper => [:email, :reference])
          content << ENABLE_RECURRING_CONTRACTS_PARTIAL
        end
        payment_request_body(content)
      end

      def authorise_recurring_payment_request_body
        validate_parameters!(:shopper => [:email, :reference])
        content = RECURRING_PAYMENT_BODY_PARTIAL % (@params[:recurring_detail_reference] || 'LATEST')
        payment_request_body(content)
      end

      def authorise_one_click_payment_request_body
        validate_parameters!(:recurring_detail_reference,
                             :shopper => [:email, :reference],
                             :card    => [:cvc])
        content = ONE_CLICK_PAYMENT_BODY_PARTIAL % [@params[:recurring_detail_reference], @params[:card][:cvc]]
        payment_request_body(content)
      end

      def payment_request_body(content)
        validate_parameters!(:merchant_account, :reference, :amount => [:currency, :value])
        content << amount_partial
        content << installments_partial if @params[:installments]
        content << shopper_partial if @params[:shopper]
        content << fraud_offset_partial if @params[:fraud_offset]
        LAYOUT % [@params[:merchant_account], @params[:reference], content]
      end

      def capture_request_body
        CAPTURE_LAYOUT % capture_and_refund_params
      end

      def refund_request_body
        REFUND_LAYOUT % capture_and_refund_params
      end

      def cancel_or_refund_request_body
        validate_parameters!(:merchant_account, :psp_reference)
        CANCEL_OR_REFUND_LAYOUT % [@params[:merchant_account], @params[:psp_reference]]
      end

      def cancel_request_body
        validate_parameters!(:merchant_account, :psp_reference)
        CANCEL_LAYOUT % [@params[:merchant_account], @params[:psp_reference]]
      end

      def capture_and_refund_params
        validate_parameters!(:merchant_account, :psp_reference, :amount => [:currency, :value])
        [@params[:merchant_account], @params[:psp_reference], *@params[:amount].values_at(:currency, :value)]
      end

      def amount_partial
        AMOUNT_PARTIAL % @params[:amount].values_at(:currency, :value)
      end

      def card_partial
        if @params[:card] and @params[:card][:encrypted] and @params[:card][:encrypted][:json]
          ENCRYPTED_CARD_PARTIAL % [@params[:card][:encrypted][:json]]
        else
          validate_parameters!(:card => [:holder_name, :number, :cvc, :expiry_year, :expiry_month])
          card  = @params[:card].values_at(:holder_name, :number, :cvc, :expiry_year)
          card << @params[:card][:expiry_month].to_i
          CARD_PARTIAL % card
        end
      end

      def installments_partial
        if @params[:installments] and @params[:installments][:value]
          INSTALLMENTS_PARTIAL % @params[:installments].values_at(:value)
        end
      end

      def shopper_partial
        @params[:shopper].map { |k, v| SHOPPER_PARTIALS[k] % v }.join("\n")
      end

      def fraud_offset_partial
        validate_parameters!(:fraud_offset)
        FRAUD_OFFSET_PARTIAL % @params[:fraud_offset]
      end

      class AuthorisationResponse < Response
        ERRORS = {
          "validation 101 Invalid card number"                           => [:number,       'is not a valid creditcard number'],
          "validation 103 CVC is not the right length"                   => [:cvc,          'is not the right length'],
          "validation 128 Card Holder Missing"                           => [:holder_name,  "can't be blank"],
          "validation Couldn't parse expiry year"                        => [:expiry_year,  'could not be recognized'],
          "validation Expiry month should be between 1 and 12 inclusive" => [:expiry_month, 'could not be recognized'],
        }

        AUTHORISED = 'Authorised'
        REFUSED    = 'Refused'

        response_attrs :result_code, :auth_code, :refusal_reason, :psp_reference

        def success?
          super && params[:result_code] == AUTHORISED
        end

        def refused?
          params[:result_code] == REFUSED
        end

        alias_method :authorised?, :success?
        alias_method :authorized?, :success?

        # @return [Boolean] Returns whether or not the request was valid.
        def invalid_request?
          !fault_message.nil?
        end

        # In the case of a validation error, or SOAP fault message, this method will return an
        # array describing what attribute failed validation and the accompanying message. If the
        # errors is not of the common user validation errors, then the attribute is +:base+ and the
        # full original message is returned.
        #
        # An optional +prefix+ can be given so you can seamlessly integrate this in your
        # ActiveRecord model and copy over errors.
        #
        # @param [String,Symbol] prefix A string that should be used to prefix the error key.
        # @return [Array<Symbol, String>] A name-message pair of the attribute with an error.
        def error(prefix = nil)
          if error = ERRORS[fault_message]
            prefix ? ["#{prefix}_#{error[0]}".to_sym, error[1]] : error
          elsif fault_message
            [:base, fault_message]
          elsif refused?
            [:base, 'Transaction was refused.']
          else
            [:base, 'Transaction failed for unkown reasons.']
          end
        end

        def params
          @params ||= xml_querier.xpath('//payment:authoriseResponse/payment:paymentResult') do |result|
            {
              :psp_reference  => result.text('./payment:pspReference'),
              :result_code    => result.text('./payment:resultCode'),
              :auth_code      => result.text('./payment:authCode'),
              :refusal_reason => (invalid_request? ? fault_message : result.text('./payment:refusalReason'))
            }
          end
        end
      end

      class ModificationResponse < Response
        class << self
          # @private
          attr_accessor :request_received_value, :base_xpath
        end

        response_attrs :psp_reference, :response

        # This only returns whether or not the request has been successfully received. Check the
        # subsequent notification to see if the payment was actually mutated.
        def success?
          super && params[:response] == self.class.request_received_value
        end

        def params
          @params ||= xml_querier.xpath(self.class.base_xpath) do |result|
            {
              :psp_reference  => result.text('./payment:pspReference'),
              :response       => result.text('./payment:response')
            }
          end
        end
      end

      class CaptureResponse < ModificationResponse
        self.request_received_value = '[capture-received]'
        self.base_xpath = '//payment:captureResponse/payment:captureResult'
      end

      class RefundResponse < ModificationResponse
        self.request_received_value = '[refund-received]'
        self.base_xpath = '//payment:refundResponse/payment:refundResult'
      end

      class CancelResponse < ModificationResponse
        self.request_received_value = '[cancel-received]'
        self.base_xpath = '//payment:cancelResponse/payment:cancelResult'
      end

      class CancelOrRefundResponse < ModificationResponse
        self.request_received_value = '[cancelOrRefund-received]'
        self.base_xpath = '//payment:cancelOrRefundResponse/payment:cancelOrRefundResult'
      end
    end
  end
end
