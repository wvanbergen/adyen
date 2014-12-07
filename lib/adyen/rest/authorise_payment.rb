module Adyen
  module REST

    # This module implements the Payment.authorise API call
    module AuthorisePayment
      def authorise_payment(attributes)
        request = Adyen::REST::Request.new('Payment.authorise', attributes, prefix: 'payment_request')
        execute_api_call(request, Adyen::REST::Response, prefix: 'payment_result')
      end

      def authorise_payment_3dsecure(attributes)
        request = Adyen::REST::Request.new('Payment.authorise3d', attributes, prefix: 'payment_request_3d')
        execute_api_call(request, Adyen::REST::Response, prefix: 'payment_result')
      end
    end
  end
end
