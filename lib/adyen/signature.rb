require File.expand_path('../invalid_signature', __FILE__)

class Adyen::Signature
  class << self
    # Calculates the payment request signature for the given payment parameters.
    #
    # This signature is used by Adyen to check whether the request is
    # genuinely originating from you. The resulting signature should be
    # included in the payment request parameters as the +merchantSig+
    # parameter; the shared secret should of course not be included.
    #
    # @param [Hash] parameters The payment parameters for which to calculate
    #    the payment request signature.
    # @param [String] shared_secret The shared secret to use for this signature.
    #    It should correspond with the skin_code parameter. This parameter can be
    #    left out if the shared_secret is included as key in the parameters.
    # @return [String] The signature of the payment request
    # @raise [ArgumentError] Thrown if shared_secret is empty
    def calculate_signature(parameters, shared_secret = nil)
      shared_secret ||= parameters.delete(:shared_secret)
      raise ArgumentError, "Cannot calculate payment request signature with empty shared_secret" if shared_secret.to_s.empty?
      Adyen::Encoding.hmac_base64(shared_secret, calculate_signature_string(parameters))
    end

    # Generates the string that is used to calculate the request signature. This signature
    # is used by Adyen to check whether the request is genuinely originating from you.
    # @param [Hash] parameters The parameters that will be included in the payment request.
    # @return [String] The string for which the siganture is calculated.
    def calculate_signature_string(parameters)
      merchant_sig_string = ""
      merchant_sig_string << parameters[:payment_amount].to_s       << parameters[:currency_code].to_s        <<
          parameters[:ship_before_date].to_s     << parameters[:merchant_reference].to_s   <<
          parameters[:skin_code].to_s            << parameters[:merchant_account].to_s     <<
          parameters[:session_validity].to_s     << parameters[:shopper_email].to_s        <<
          parameters[:shopper_reference].to_s    << parameters[:recurring_contract].to_s   <<
          parameters[:allowed_methods].to_s      << parameters[:blocked_methods].to_s      <<
          parameters[:shopper_statement].to_s    << parameters[:merchant_return_data].to_s <<
          parameters[:billing_address_type].to_s << parameters[:offset].to_s
    end

    ######################################################
    # REDIRECT SIGNATURE CHECKING
    ######################################################

    # Checks the redirect signature for this request by calcultating the signature from
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
    #       raise "Forgery!" unless Adyen::Form.redirect_signature_check(params)
    #     end
    #   end
    #
    # @param [Hash] params params A hash of HTTP GET parameters for the redirect request. This
    #      should include the +:merchantSig+ parameter, which contains the signature.
    # @param [String] shared_secret The shared secret for the Adyen skin that was used for
    #     the original payment form. You can leave this out of the skin is registered
    #     using the {Adyen::Configuration#register_form_skin} method.
    # @return [true, false] Returns true only if the signature in the parameters is correct.
    def redirect_signature_check(params, shared_secret = nil)
      Adyen::PaymentResult.new(params).has_valid_signature?(shared_secret)
    end

    # Computes the redirect signature using the request parameters, so that the
    # redirect can be checked for forgery.
    #
    # @param [Hash] params A hash of HTTP GET parameters for the redirect request.
    # @param [String] shared_secret The shared secret for the Adyen skin that was used for
    #     the original payment form. You can leave this out of the skin is registered
    #     using the {Adyen::Form.register_skin} method.
    # @return [String] The redirect signature
    # @raise [ArgumentError] Thrown if shared_secret is empty
    # @deprecated Please use Adyen::PaymentResult#signature directly, not this method
    def redirect_signature(params, shared_secret = nil)
      Adyen::PaymentResult.new(params).signature(shared_secret)
    end

    # Generates the string for which the redirect signature is calculated, using the request paramaters.
    # @param [Hash] params A hash of HTTP GET parameters for the redirect request.
    # @return [String] The signature string.
    # @deprecated Please use Adyen::PaymentResult#signature_string directly, not this method
    def redirect_signature_string(params)
      Adyen::PaymentResult.new(params).signature_string
    end
  end
end
