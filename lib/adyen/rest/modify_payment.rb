module Adyen
  module REST

    # This module implements the <b>Payment.capture</b> API to capture
    # previously authorised payments.
    module ModifyPayment
      class Request < Adyen::REST::Request
        def set_modification_amount(currency, value)
          self['modification_amount'] = { currency: currency, value: value }
        end

        alias_method :set_amount, :set_modification_amount
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
          response_class: Adyen::REST::ModifyPayment::Response,
          response_options: {
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
          response_class: Adyen::REST::ModifyPayment::Response,
          response_options: {
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
          response_class: Adyen::REST::ModifyPayment::Response,
          response_options: {
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
          response_class: Adyen::REST::ModifyPayment::Response,
          response_options: {
            expects: '[cancelOrRefund-received]'
          }
        )
      end
    end
  end
end
