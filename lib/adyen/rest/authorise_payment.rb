module Adyen
  module REST

    # This module implements the Payment.authorise API call
    module AuthorisePayment

      class Response < Adyen::REST::Response
        def authorised?
          result_code == AUTHORISED
        end

        alias_method :authorized?, :authorised?

        def redirect_shopper?
          result_code == REDIRECT_SHOPPER
        end

        AUTHORISED       = 'Authorised'.freeze
        REDIRECT_SHOPPER = 'RedirectShopper'.freeze
        private_constant :AUTHORISED, :REDIRECT_SHOPPER
      end

      def authorise_payment(attributes)
        request = Adyen::REST::Request.new('Payment.authorise', attributes, prefix: 'payment_request')
        execute_api_call(request, Adyen::REST::AuthorisePayment::Response, prefix: 'payment_result')
      end

      alias_method :authorize_payment, :authorise_payment

      def authorise_payment_3dsecure(attributes)
        request = Adyen::REST::Request.new('Payment.authorise3d', attributes, prefix: 'payment_request_3d')
        execute_api_call(request, Adyen::REST::AuthorisePayment::Response, prefix: 'payment_result')
      end

      alias_method :authorize_payment_3dsecure, :authorise_payment_3dsecure
    end
  end
end
