class Adyen::RedirectSignature
  def initialize(params)
    @params = params.inject({}) do |hash, pair|
      hash[pair.first.to_sym] = pair.last
      hash
    end
  end

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
  def redirect_signature_check(shared_secret = nil)
    @params[:merchantSig] == redirect_signature(shared_secret)
  end

  # Computes the redirect signature using the request parameters, so that the
  # redirect can be checked for forgery.
  #
  # @param [String] shared_secret The shared secret for the Adyen skin that was used for
  #     the original payment form. You can leave this out of the skin is registered
  #     using the {Adyen::Form.register_skin} method.
  # @return [String] The redirect signature
  # @raise [ArgumentError] Thrown if shared_secret is empty
  def redirect_signature(shared_secret = nil)
    shared_secret ||= Adyen.configuration.form_skin_shared_secret_by_code(@params[:skinCode])
    raise ArgumentError, "Cannot compute redirect signature with empty shared_secret" if shared_secret.to_s.empty?
    Adyen::Encoding.hmac_base64(shared_secret, redirect_signature_string)
  end

  # Generates the string for which the redirect signature is calculated, using the request paramaters.
  # @return [String] The signature string.
  def redirect_signature_string
    @params[:authResult].to_s + @params[:pspReference].to_s + @params[:merchantReference].to_s +
        @params[:skinCode].to_s + @params[:merchantReturnData].to_s
  end

  def payment_success?
    @params[:authResult] == 'AUTHORISED'
  end
end
