module Adyen
  module REST

    # This module implements the Payment.authorise API call
    module AuthorisePayment
      def authorise_payment(attributes)
        request = Adyen::REST::Request.new('Payment.authorise', 'payment_request', 'payment_result', attributes)
        execute_api_call(request)
      end

      def authorise_payment_3dsecure(attributes)
        request = Adyen::REST::Request.new('Payment.authorise3d', 'payment_request_3d', 'payment_result', attributes)
        execute_api_call(request)
      end
    end
  end
end
