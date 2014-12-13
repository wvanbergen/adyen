module Adyen
  module REST

    # This module implements the <b>Payment.capture</b> API to capture
    # previously authorised payments.
    module ModifyPayment
      class Request < Adyen::REST::Request
        def set_amount(currency, value)
          self['modification_amount'] = { currency: currency, value: value }
        end
      end

      class Response < Adyen::REST::Response
        attr_reader :expected_response

        def initialize(http_response, options = {})
          super
          @expected_response = options[:expects]
        end

        def received?
          self[:response] == expected_response
        end
      end

      # Constructs and issues a Payment.capture API call.
      def capture_payment(attributes = {})
        request = capture_payment_request(attributes)
        execute_request(request)
      end

      def capture_payment_request(attributes = {})
        Adyen::REST::ModifyPayment::Request.new('Payment.capture', attributes,
          prefix: 'modification_request',
          response_class: Adyen::REST::ModifyPayment::Response,
          response_options: {
            prefix: 'modification_result',
            expects: '[capture-received]'
          }
        )
      end

      # Constructs and issues a Payment.cancel API call.
      def cancel_payment(attributes = {})
        request = cancel_payment_request(attributes)
        execute_request(request)
      end

      def cancel_payment_request(attributes = {})
        Adyen::REST::ModifyPayment::Request.new('Payment.cancel', attributes,
          prefix: 'modification_request',
          response_class: Adyen::REST::ModifyPayment::Response,
          response_options: {
            prefix: 'modification_result',
            expects: '[cancel-received]'
          }
        )
      end

      # Constructs and issues a Payment.cancel API call.
      def refund_payment(attributes = {})
        request = refund_payment_request(attributes)
        execute_request(request)
      end

      def refund_payment_request(attributes = {})
        Adyen::REST::ModifyPayment::Request.new('Payment.refund', attributes,
          prefix: 'modification_request',
          response_class: Adyen::REST::ModifyPayment::Response,
          response_options: {
            prefix: 'modification_result',
            expects: '[refund-received]'
          }
        )
      end

      # Constructs and issues a Payment.cancel API call.
      def cancel_or_refund_payment(attributes = {})
        request = cancel_or_refund_payment_request(attributes)
        execute_request(request)
      end

      def cancel_or_refund_payment_request(attributes = {})
        Adyen::REST::ModifyPayment::Request.new('Payment.cancelOrRefund', attributes,
          prefix: 'modification_request',
          response_class: Adyen::REST::ModifyPayment::Response,
          response_options: {
            prefix: 'modification_result',
            expects: '[cancelOrRefund-received]'
          }
        )
      end
    end
  end
end
