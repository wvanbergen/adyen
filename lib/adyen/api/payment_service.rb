require 'adyen/api/simple_soap_client'
require 'adyen/api/templates/payment_service'

module Adyen
  module API
    class PaymentService < SimpleSOAPClient
      ENDPOINT_URI = 'https://pal-%s.adyen.com/pal/servlet/soap/Payment'

      def authorise_payment
        make_payment_request(authorise_payment_request_body, AuthorizationResponse)
      end

      def authorise_recurring_payment
        make_payment_request(authorise_recurring_payment_request_body, AuthorizationResponse)
      end

      def authorise_one_click_payment
        make_payment_request(authorise_one_click_payment_request_body, AuthorizationResponse)
      end

      def capture
        make_payment_request(capture_request_body, CaptureResponse)
      end

      # Also returns success if the amount is not the same as the original payment.
      # You should check the status on the notification that will be send.
      def refund
        make_payment_request(refund_request_body, RefundResponse)
      end

      def cancel
        make_payment_request(cancel_request_body, CancelResponse)
      end

      def cancel_or_refund
        make_payment_request(cancel_or_refund_request_body, CancelOrRefundResponse)
      end

      private

      def make_payment_request(data, response_class)
        call_webservice_action('authorise', data, response_class)
      end

      def authorise_payment_request_body
        content = card_partial
        content << ENABLE_RECURRING_CONTRACTS_PARTIAL if @params[:recurring]
        payment_request_body(content)
      end

      def authorise_recurring_payment_request_body
        content = RECURRING_PAYMENT_BODY_PARTIAL % (@params[:recurring_detail_reference] || 'LATEST')
        payment_request_body(content)
      end

      def authorise_one_click_payment_request_body
        content = ONE_CLICK_PAYMENT_BODY_PARTIAL % [@params[:recurring_detail_reference], @params[:card][:cvc]]
        payment_request_body(content)
      end

      def payment_request_body(content)
        content << amount_partial
        content << shopper_partial if @params[:shopper]
        LAYOUT % [@params[:merchant_account], @params[:reference], content]
      end

      def capture_request_body
        CAPTURE_LAYOUT % capture_and_refund_params
      end

      def refund_request_body
        REFUND_LAYOUT % capture_and_refund_params
      end

      def cancel_or_refund_request_body
        CANCEL_OR_REFUND_LAYOUT % [@params[:merchant_account], @params[:psp_reference]]
      end

      def cancel_request_body
        CANCEL_LAYOUT % [@params[:merchant_account], @params[:psp_reference]]
      end

      def capture_and_refund_params
        [@params[:merchant_account], @params[:psp_reference], *@params[:amount].values_at(:currency, :value)]
      end

      def amount_partial
        AMOUNT_PARTIAL % @params[:amount].values_at(:currency, :value)
      end

      def card_partial
        card  = @params[:card].values_at(:holder_name, :number, :cvc, :expiry_year)
        card << @params[:card][:expiry_month].to_i
        CARD_PARTIAL % card
      end

      def shopper_partial
        @params[:shopper].map { |k, v| SHOPPER_PARTIALS[k] % v }.join("\n")
      end

      class AuthorizationResponse < Response
        ERRORS = {
          "validation 101 Invalid card number"                           => [:number,       'is not a valid creditcard number'],
          "validation 103 CVC is not the right length"                   => [:cvc,          'is not the right length'],
          "validation 128 Card Holder Missing"                           => [:holder_name,  'can’t be blank'],
          "validation Couldn't parse expiry year"                        => [:expiry_year,  'could not be recognized'],
          "validation Expiry month should be between 1 and 12 inclusive" => [:expiry_month, 'could not be recognized'],
        }

        AUTHORISED = 'Authorised'

        def self.original_fault_message_for(attribute, message)
          if error = ERRORS.find { |_, (a, m)| a == attribute && m == message }
            error.first
          else
            message
          end
        end

        response_attrs :result_code, :auth_code, :refusal_reason, :psp_reference

        def success?
          super && params[:result_code] == AUTHORISED
        end

        alias authorized? success?

        def invalid_request?
          !fault_message.nil?
        end

        def error(prefix = nil)
          if error = ERRORS[fault_message]
            prefix ? ["#{prefix}_#{error[0]}".to_sym, error[1]] : error
          else
            [:base, fault_message]
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
          attr_accessor :request_received_value
          attr_accessor :base_xpath
        end

        response_attrs :psp_reference, :response

        # This only means the request has been successfully received.
        # Check the notification to see if it was actually refunded.
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
