module Adyen
  module REST
    # This module implements the <b>Payout</b>
    # API calls, and includes a custom response class to make handling the response easier.
    # https://docs.adyen.com/developers/payout-manual
    module Payout
      class Request < Adyen::REST::Request
      end

      class Response < Adyen::REST::Response

        def success?
          result_code == SUCCESS
        end

        def received?
          result_code == RECEIVED
        end

        def confirmed?
          response == CONFIRMED
        end

        def declined?
          response == DECLINED
        end

        def result_code
          self[:result_code]
        end

        def psp_reference
          self[:psp_reference]
        end

        def response
          self[:response]
        end

        SUCCESS          = 'Success'.freeze
        RECEIVED         = '[payout-submit-received]'.freeze
        CONFIRMED        = '[payout-confirm-received]'.freeze
        DECLINED         = '[payout-decline-received]'.freeze
        private_constant :SUCCESS, :RECEIVED, :CONFIRMED, :DECLINED
      end

      # Constructs and issues a Payment.capture API call.
      def store_payout(attributes = {})
        request = store_request('Payout.storeDetail', attributes)
        execute_request(request)
      end

      def submit_payout(attributes = {})
        request = store_request('Payout.submit', attributes)
        execute_request(request)
      end

      def submit_and_store_payout(attributes = {})
        request = store_request('Payout.storeDetailAndSubmit', attributes)
        execute_request(request)
      end

      def confirm_payout(attributes = {})
        request = review_request('Payout.confirm', attributes)
        execute_request(request)
      end

      def decline_payout(attributes = {})
        request = review_request('Payout.decline', attributes)
        execute_request(request)
      end

      private
      # Require you to use a client initialize with payout_store
      def store_request(action, attributes)
        Adyen::REST::Payout::Request.new(action, attributes,
          response_class: Adyen::REST::Payout::Response
        )
      end

      # Require you to use a client initialize with payout review
      def review_request(action, attributes)
        Adyen::REST::Payout::Request.new(action, attributes,
          response_class: Adyen::REST::Payout::Response
        )
      end
    end
  end
end
