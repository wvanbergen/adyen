require 'adyen/api/templates/elv_service'

module Adyen
  module API
    class ElvPaymentService < PaymentService
      include Elv

      def authorise_payment
        make_payment_request(authorise_payment_request_body, AuthorisationResponse)
      end

      private

      def authorise_payment_request_body
        payment_request_body elv_partial(:recurring => false)
      end
    end
  end
end

