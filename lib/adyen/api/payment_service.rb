require 'adyen/api/simple_soap_client'
require 'adyen/api/templates/payment_service'

module Adyen
  module API
    class PaymentService < SimpleSOAPClient
      ENDPOINT_URI = 'https://pal-%s.adyen.com/pal/servlet/soap/Payment'

      class << self
        def success_stub
          http_response = Net::HTTPOK.new('1.1', '200', 'OK')
          def http_response.body; AUTHORISE_RESPONSE; end
          AuthorizationResponse.new(http_response)
        end

        def refused_stub
          http_response = Net::HTTPOK.new('1.1', '200', 'OK')
          def http_response.body; AUTHORISATION_REFUSED_RESPONSE; end
          AuthorizationResponse.new(http_response)
        end

        def invalid_stub
          http_response = Net::HTTPOK.new('1.1', '200', 'OK')
          def http_response.body; AUTHORISATION_REQUEST_INVALID_RESPONSE; end
          AuthorizationResponse.new(http_response)
        end

        def stub_success!
          @stubbed_response = success_stub
        end

        def stub_refused!
          @stubbed_response = refused_stub
        end

        def stub_invalid!
          @stubbed_response = invalid_stub
        end
      end

      def authorise_payment
        make_payment_request(authorise_payment_request_body, AuthorizationResponse)
      end

      def authorise_recurring_payment
        make_payment_request(authorise_recurring_payment_request_body, AuthorizationResponse)
      end

      # Also returns success if the amount is not the same as the original payment.
      # You should check the status on the notification that will be send.
      def refund
        make_payment_request(refund_body, RefundResponse)
      end

      def cancel_or_refund
        make_payment_request(cancel_or_refund_body, CancelOrRefundResponse)
      end

      private

      def make_payment_request(data, response_class)
        call_webservice_action('authorise', data, response_class)
      end

      def authorise_payment_request_body
        content = card_partial
        content << RECURRING_PARTIAL if @params[:recurring]
        payment_request_body(content)
      end

      def authorise_recurring_payment_request_body
        content = RECURRING_PAYMENT_BODY_PARTIAL % (@params[:recurring_detail_reference] || 'LATEST')
        payment_request_body(content)
      end

      def payment_request_body(content)
        content << amount_partial
        content << shopper_partial if @params[:shopper]
        LAYOUT % [@params[:merchant_account], @params[:reference], content]
      end

      def refund_body
        REFUND_LAYOUT % [@params[:merchant_account], @params[:psp_reference], *@params[:amount].values_at(:currency, :value)]
      end

      def cancel_or_refund_body
        CANCEL_OR_REFUND_LAYOUT % [@params[:merchant_account], @params[:psp_reference]]
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

      class CancelOrRefundResponse < Response
        class << self
          attr_accessor :request_received_value
          attr_accessor :base_xpath
        end
        self.request_received_value = '[cancelOrRefund-received]'
        self.base_xpath = '//payment:cancelOrRefundResponse/payment:cancelOrRefundResult'

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

      class RefundResponse < CancelOrRefundResponse
        self.request_received_value = '[refund-received]'
        self.base_xpath = '//payment:refundResponse/payment:refundResult'
      end
    end
  end
end
