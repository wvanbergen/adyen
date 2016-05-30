require 'cgi'

module Adyen

  # The Adyen::Form module contains all functionality that is used to send payment requests
  # to the Adyen payment system, using either a HTML form (see {Adyen::Form.hidden_fields})
  # or a HTTP redirect (see {Adyen::Form.redirect_url}).
  #
  # Moreover, this module contains the method {Adyen::Form.redirect_signature_check} to
  # check the request, that is made to your website after the visitor has made his payment
  # on the Adyen system, for genuinity.
  #
  # You can use different skins in Adyen to define different payment environments. You can
  # register these skins under a custom name in the module. The other methods will automatically
  # use this information (i.e. the skin code and the shared secret) if it is available.
  # Otherwise, you have to provide it yourself for every method call you make. See
  # {Adyen::Configuration#register_form_skin} for more information.
  #
  # @see Adyen::Configuration#register_form_skin
  # @see Adyen::Form.hidden_fields
  # @see Adyen::Form.redirect_url
  # @see Adyen::Form.redirect_signature_check
  module Form
    extend self

    ######################################################
    # ADYEN FORM URL
    ######################################################

    # The DOMAIN of the Adyen payment system that still requires the current
    # Adyen enviroment.
    ACTION_DOMAIN = "%s.adyen.com"

    # The URL of the Adyen payment system that still requires the current
    # domain and payment flow to be filled.
    ACTION_URL = "https://%s/hpp/%s.shtml"

    # Returns the DOMAIN of the Adyen payment system, adjusted for an Adyen environment.
    #
    # @param [String] environment The Adyen environment to use. This parameter can be
    #    left out, in which case the 'current' environment will be used.
    # @return [String] The domain of the Adyen payment system that can be used
    #    for payment forms or redirects.
    # @see Adyen::Form.environment
    # @see Adyen::Form.redirect_url
    def domain(environment = nil)
      environment  ||= Adyen.configuration.environment
      (Adyen.configuration.payment_flow_domain || ACTION_DOMAIN) % [environment.to_s]
    end

    # Returns the URL of the Adyen payment system, adjusted for an Adyen environment.
    #
    # @param [String] environment The Adyen environment to use. This parameter can be
    #    left out, in which case the 'current' environment will be used.
    # @param [String] payment_flow The Adyen payment type to use. This parameter can be
    #    left out, in which case the default payment type will be used.
    # @return [String] The absolute URL of the Adyen payment system that can be used
    #    for payment forms or redirects.
    # @see Adyen::Form.environment
    # @see Adyen::Form.domain
    # @see Adyen::Form.redirect_url
    def url(environment = nil, payment_flow = nil)
      payment_flow ||= Adyen.configuration.payment_flow
      Adyen::Form::ACTION_URL % [domain(environment), payment_flow.to_s]
    end

    ######################################################
    # POSTING/REDIRECTING TO ADYEN
    ######################################################

    # Transforms the payment parameters hash to be in the correct format. It will also
    # include the Adyen::Configuration#default_form_params hash. Finally, switches the
    # +:skin+ parameter out for the +:skin_code+ and +:shared_secret+  parameter using
    # the list of registered skins.
    #
    # @private
    # @param [Hash] parameters The payment parameters hash to transform
    def do_parameter_transformations!(parameters = {})
      parameters.replace(Adyen.configuration.default_form_params.merge(parameters))

      if parameters[:skin]
        skin = Adyen.configuration.form_skin_by_name(parameters.delete(:skin))
        parameters[:skin_code]     ||= skin[:skin_code]
        parameters[:shared_secret] ||= skin[:shared_secret]
        parameters.merge!(skin[:default_form_params])
      end

      parameters[:recurring_contract] = 'RECURRING' if parameters.delete(:recurring) == true
      parameters[:order_data]         = Adyen::Util.gzip_base64(parameters.delete(:order_data_raw)) if parameters[:order_data_raw]
      parameters[:ship_before_date]   = Adyen::Util.format_date(parameters[:ship_before_date])
      parameters[:session_validity]   = Adyen::Util.format_timestamp(parameters[:session_validity])
    end

    # Transforms the payment parameters to be in the correct format and calculates the merchant
    # signature parameter. It also does some basic health checks on the parameters hash.
    #
    # @param [Hash] parameters The payment parameters. The parameters set in the
    #    {Adyen::Configuration#default_form_params} hash will be included automatically.
    # @param [String] shared_secret The shared secret that should be used to calculate
    #    the payment request signature. This parameter can be left if the skin that is
    #    used is registered (see {Adyen::Configuration#register_form_skin}), or if the
    #    shared secret is provided as the +:shared_secret+ parameter.
    # @return [Hash] The payment parameters with the +:merchant_signature+ parameter set.
    # @raise [ArgumentError] Thrown if some parameter health check fails.
    def payment_parameters(parameters = {}, shared_secret = nil)
      raise ArgumentError, "Cannot generate form: parameters should be a hash!" unless parameters.is_a?(Hash)
      do_parameter_transformations!(parameters)

      raise ArgumentError, "Cannot generate form: :currency code attribute not found!"         unless parameters[:currency_code]
      raise ArgumentError, "Cannot generate form: :payment_amount code attribute not found!"   unless parameters[:payment_amount]
      raise ArgumentError, "Cannot generate form: :merchant_account attribute not found!"      unless parameters[:merchant_account]
      raise ArgumentError, "Cannot generate form: :skin_code attribute not found!"             unless parameters[:skin_code]

      # Calculate the merchant signature using the shared secret.
      shared_secret ||= parameters.delete(:shared_secret)
      raise ArgumentError, "Cannot calculate payment request signature without shared secret!" unless shared_secret
      parameters[:merchant_sig] = calculate_signature(parameters, shared_secret)

      if parameters[:billing_address]
        parameters[:billing_address_sig] = calculate_billing_address_signature(parameters, shared_secret)
      end

      if parameters[:delivery_address]
        parameters[:delivery_address_sig] = calculate_delivery_address_signature(parameters, shared_secret)
      end

      if parameters[:shopper]
        parameters[:shopper_sig] = calculate_shopper_signature(parameters, shared_secret)
      end

      if parameters[:openinvoicedata]
        parameters[:openinvoicedata][:sig] = calculate_open_invoice_signature(parameters, shared_secret)
      end

      return parameters
    end

    # Transforms and flattens payment parameters to be in the correct format which is understood and accepted by adyen
    #
    # @param [Hash] parameters The payment parameters. The parameters set in the
    #    {Adyen::Configuration#default_form_params} hash will be included automatically.
    # @return [Hash] The payment parameters flatten, with camelized and prefixed key, stringified value
    def flat_payment_parameters(parameters = {})
      Adyen::Util.flatten(payment_parameters(parameters))
    end

    # Returns an absolute URL to the Adyen payment system, with the payment parameters included
    # as GET parameters in the URL. The URL also depends on the current Adyen enviroment.
    #
    # The payment parameters that are provided to this method will be merged with the
    # {Adyen::Configuration#default_form_params} hash. The default parameter values will be
    # overrided if another value is provided to this method.
    #
    # You do not have to provide the +:merchant_sig+ parameter: it will be calculated automatically
    # if you provide either a registered skin name as the +:skin+ parameter or provide both the
    # +:skin_code+ and +:shared_secret+ parameters.
    #
    # Note that Internet Explorer has a maximum length for URLs it can handle (2083 characters).
    # Make sure that the URL is not longer than this limit if you want your site to work in IE.
    #
    # @example
    #
    #    def pay
    #      # Genarate a URL to redirect to Adyen's payment system.
    #      adyen_url = Adyen::Form.redirect_url(:skin => :my_skin, :currency_code => 'USD',
    #            :payment_amount => 1000, merchant_account => 'MyMerchant', ... )
    #
    #      respond_to do |format|
    #        format.html { redirect_to(adyen_url) }
    #      end
    #    end
    #
    # @param [Hash] parameters The payment parameters to include in the payment request.
    # @return [String] An absolute URL to redirect to the Adyen payment system.
    def redirect_url(parameters = {})
      url + '?' + flat_payment_parameters(parameters).map { |(k, v)|
        "#{k}=#{CGI.escape(v)}"
      }.join('&')
    end

    # @see Adyen::Form.redirect_url
    #
    # Returns an absolute URL very similar to the one returned by Adyen::Form.redirect_url
    # except that it uses the directory.shtml call which returns a list of all available
    # payment methods
    #
    # @param [Hash] parameters The payment parameters to include in the payment request.
    # @return [String] An absolute URL to redirect to the Adyen payment system.
    def payment_methods_url(parameters = {})
      url(nil, :directory) + '?' + flat_payment_parameters(parameters).map { |(k, v)|
        "#{k}=#{CGI.escape(v)}"
      }.join('&')
    end

    # Returns a HTML snippet of hidden INPUT tags with the provided payment parameters.
    # The snippet can be included in a payment form that POSTs to the Adyen payment system.
    #
    # The payment parameters that are provided to this method will be merged with the
    # {Adyen::Configuration#default_form_params} hash. The default parameter values will be
    # overrided if another value is provided to this method.
    #
    # You do not have to provide the +:merchant_sig+ parameter: it will be calculated automatically
    # if you provide either a registered skin name as the +:skin+ parameter or provide both the
    # +:skin_code+ and +:shared_secret+ parameters.
    #
    # @example
    #    <% form_tag(Adyen::Form.url) do %>
    #      <%= Adyen::Form.hidden_fields(:skin => :my_skin, :currency_code => 'USD',
    #            :payment_amount => 1000, ...) %>
    #      <%= submit_tag("Pay invoice")
    #    <% end %>
    #
    # @param [Hash] parameters The payment parameters to include in the payment request.
    # @return [String] An HTML snippet that can be included in a form that POSTs to the
    #       Adyen payment system.
    def hidden_fields(parameters = {})

      # Generate a hidden input tag per parameter, join them by newlines.
      form_str = flat_payment_parameters(parameters).map { |key, value|
        "<input type=\"hidden\" name=\"#{CGI.escapeHTML(key)}\" value=\"#{CGI.escapeHTML(value)}\" />"
      }.join("\n")

      form_str.respond_to?(:html_safe) ? form_str.html_safe : form_str
    end

    ######################################################
    # MERCHANT SIGNATURE CALCULATION
    ######################################################

    # Generates the string that is used to calculate the request signature. This signature
    # is used by Adyen to check whether the request is genuinely originating from you.
    # @param [Hash] parameters The parameters that will be included in the payment request.
    # @return [String] The string for which the siganture is calculated.
    def calculate_signature_string(parameters)
      merchant_sig_string = ""
      merchant_sig_string << parameters[:payment_amount].to_s       << parameters[:currency_code].to_s         <<
                             parameters[:ship_before_date].to_s     << parameters[:merchant_reference].to_s    <<
                             parameters[:skin_code].to_s            << parameters[:merchant_account].to_s      <<
                             parameters[:session_validity].to_s     << parameters[:shopper_email].to_s         <<
                             parameters[:shopper_reference].to_s    << parameters[:recurring_contract].to_s    <<
                             parameters[:allowed_methods].to_s      << parameters[:blocked_methods].to_s       <<
                             parameters[:shopper_statement].to_s    << parameters[:merchant_return_data].to_s  <<
                             parameters[:billing_address_type].to_s << parameters[:delivery_address_type].to_s <<
                             parameters[:shopper_type].to_s         << parameters[:offset].to_s
    end

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
      Adyen::Util.hmac_base64(shared_secret, calculate_signature_string(parameters))
    end

    # Generates the string that is used to calculate the request signature. This signature
    # is used by Adyen to check whether the request is genuinely originating from you.
    # @param [Hash] parameters The parameters that will be included in the billing address request.
    # @return [String] The string for which the siganture is calculated.
    def calculate_billing_address_signature_string(parameters)
      %w(street house_number_or_name city postal_code state_or_province country).map do |key|
        parameters[key.to_sym]
      end.join
    end

    # Generates the string that is used to calculate the request signature. This signature
    # is used by Adyen to check whether the request is genuinely originating from you.
    # @param [Hash] parameters The parameters that will be included in the delivery address request.
    # @return [String] The string for which the siganture is calculated.
    def calculate_delivery_address_signature_string(parameters)
      %w(street house_number_or_name city postal_code state_or_province country).map do |key|
        parameters[key.to_sym]
      end.join
    end

    # Calculates the billing address request signature for the given billing address parameters.
    #
    # This signature is used by Adyen to check whether the request is
    # genuinely originating from you. The resulting signature should be
    # included in the billing address request parameters as the +billingAddressSig+
    # parameter; the shared secret should of course not be included.
    #
    # @param [Hash] parameters The billing address parameters for which to calculate
    #    the billing address request signature.
    # @param [String] shared_secret The shared secret to use for this signature.
    #    It should correspond with the skin_code parameter. This parameter can be
    #    left out if the shared_secret is included as key in the parameters.
    # @return [String] The signature of the billing address request
    # @raise [ArgumentError] Thrown if shared_secret is empty
    def calculate_billing_address_signature(parameters, shared_secret = nil)
      shared_secret ||= parameters.delete(:shared_secret)
      raise ArgumentError, "Cannot calculate billing address request signature with empty shared_secret" if shared_secret.to_s.empty?
      Adyen::Util.hmac_base64(shared_secret, calculate_billing_address_signature_string(parameters[:billing_address]))
    end

    # Calculates the delivery address request signature for the given delivery address parameters.
    #
    # This signature is used by Adyen to check whether the request is
    # genuinely originating from you. The resulting signature should be
    # included in the delivery address request parameters as the +deliveryAddressSig+
    # parameter; the shared secret should of course not be included.
    #
    # @param [Hash] parameters The delivery address parameters for which to calculate
    #    the delivery address request signature.
    # @param [String] shared_secret The shared secret to use for this signature.
    #    It should correspond with the skin_code parameter. This parameter can be
    #    left out if the shared_secret is included as key in the parameters.
    # @return [String] The signature of the delivery address request
    # @raise [ArgumentError] Thrown if shared_secret is empty
    def calculate_delivery_address_signature(parameters, shared_secret = nil)
      shared_secret ||= parameters.delete(:shared_secret)
      raise ArgumentError, "Cannot calculate delivery address request signature with empty shared_secret" if shared_secret.to_s.empty?
      Adyen::Util.hmac_base64(shared_secret, calculate_delivery_address_signature_string(parameters[:delivery_address]))
    end

    # shopperSig: shopper.firstName + shopper.infix + shopper.lastName + shopper.gender + shopper.dateOfBirthDayOfMonth + shopper.dateOfBirthMonth + shopper.dateOfBirthYear + shopper.telephoneNumber
    # (Note that you can send only shopper.firstName and shopper.lastName if you like. Do NOT include shopperSocialSecurityNumber in the shopperSig!)
    def calculate_shopper_signature_string(parameters)
      %w(first_name infix last_name gender date_of_birth_day_of_month date_of_birth_month date_of_birth_year telephone_number).map do |key|
        parameters[key.to_sym]
      end.join
    end

    def calculate_shopper_signature(parameters, shared_secret = nil)
      shared_secret ||= parameters.delete(:shared_secret)
      raise ArgumentError, "Cannot calculate shopper request signature with empty shared_secret" if shared_secret.to_s.empty?
      Adyen::Util.hmac_base64(shared_secret, calculate_shopper_signature_string(parameters[:shopper]))
    end

    def calculate_open_invoice_signature_string(merchant_sig, parameters)
      flattened = Adyen::Util.flatten(:merchant_sig => merchant_sig, :openinvoicedata => parameters)
      pairs = flattened.to_a.sort
      pairs.transpose.map { |it| it.join(':') }.join('|')
    end

    def calculate_open_invoice_signature(parameters, shared_secret = nil)
      shared_secret ||= parameters.delete(:shared_secret)
      raise ArgumentError, "Cannot calculate open invoice request signature with empty shared_secret" if shared_secret.to_s.empty?
      merchant_sig = calculate_signature(parameters, shared_secret)
      Adyen::Util.hmac_base64(shared_secret, calculate_open_invoice_signature_string(merchant_sig, parameters[:openinvoicedata]))
    end

    ######################################################
    # REDIRECT SIGNATURE CHECKING
    ######################################################

    # Generates the string for which the redirect signature is calculated, using the request paramaters.
    # @param [Hash] params A hash of HTTP GET parameters for the redirect request.
    # @return [String] The signature string.
    def redirect_signature_string(params)
      params['authResult'].to_s + params['pspReference'].to_s + params['merchantReference'].to_s +
        params['skinCode'].to_s + params['merchantReturnData'].to_s
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
    def redirect_signature(params, shared_secret = nil)
      shared_secret ||= Adyen.configuration.form_skin_shared_secret_by_code(params['skinCode'])
      raise ArgumentError, "Cannot compute redirect signature with empty shared_secret" if shared_secret.to_s.empty?
      Adyen::Util.hmac_base64(shared_secret, redirect_signature_string(params))
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
    def redirect_signature_check(params, shared_secret = nil)
      raise ArgumentError, "params should be a Hash" unless params.is_a?(Hash)
      raise ArgumentError, "params should contain :merchantSig" unless params.key?('merchantSig')
      params['merchantSig'] == redirect_signature(params, shared_secret)
    end
  end
end
