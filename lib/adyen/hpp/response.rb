module Adyen
  module HPP

    class Response
      attr_reader :params, :shared_secret

      # Initialize the HPP response
      #
      # @param [Hash] params params A hash of HTTP GET parameters for the redirect request. This
      #      should include the +:merchantSig+ parameter, which contains the signature.
      # @param [String] shared_secret Optional shared secret; if not provided, the shared secret
      #     of the skin determined by params['skinCode'] will be used
      def initialize(params, shared_secret = nil)
        raise ArgumentError, "params should be a Hash" unless params.is_a?(Hash)
        raise ArgumentError, "params should contain :merchantSig" unless params.key?('merchantSig')

        @params = params
        skin = Adyen.configuration.form_skin_by_code(params['skinCode']) || {}
        @shared_secret = shared_secret || skin[:shared_secret]
      end

      # Generates the string for which the redirect signature is calculated, using the request paramaters.
      # @return [String] The signature string.
      def redirect_signature_string
        params['authResult'].to_s + params['pspReference'].to_s + params['merchantReference'].to_s +
          params['skinCode'].to_s + params['merchantReturnData'].to_s
      end

      # Computes the SHA-1 redirect signature using the request parameters, so that the
      # redirect can be checked for forgery.
      #
      # @return [String] The redirect signature
      # @raise [ArgumentError] Thrown if shared_secret is empty
      def redirect_signature
        raise ArgumentError, "Cannot compute redirect signature with empty shared_secret" unless shared_secret
        Adyen::Util.hmac_base64(shared_secret, redirect_signature_string)
      end

      # Checks the redirect signature for this request by calculating the signature from
      # the provided parameters, and comparing it to the signature provided in the +merchantSig+
      # parameter.
      #
      # If this method returns false, the request could be a forgery and should not be handled.
      # Therefore, you should include this check in a +before_filter+, and raise an error of the
      # signature check fails.
      #
      # @example
      #   class PaymentsController < ApplicationController
      #     before_filter :check_signature, :only => [:return_from_adyen]
      #
      #     def return_from_adyen
      #       @invoice = Invoice.find(params[:merchantReference])
      #       @invoice.set_paid! if params[:authResult] == 'AUTHORISED'
      #     end
      #
      #     private
      #
      #     def check_signature
      #       raise "Forgery!" unless Adyen::HPP::Response.new(params).redirect_signature_check
      #     end
      #   end
      #
      # @return [true, false] Returns true only if the signature in the parameters is correct.
      def redirect_signature_check
        params['merchantSig'] == redirect_signature
      end
    end
  end
end