require 'action_view'

module Adyen

  # The Adyen::Form module contains all functionality that is used to send payment requests 
  # to the Adyen payment system, using either a HTML form (see {Adyen::Form.hidden_fields}) 
  # or a HTTP redirect (see {Adyen::Form.redirect_url}).
  #
  # Moreover, this module contains the method {Adyen::Form.redirect_signature_check} to
  # check the request that is made to your website after the visitor has made his payment
  # on the Adyen system for genuinity.
  #
  # You can use different skins in Adyen to define different payment environments. You can
  # register these skins under a custom name in the module. The other methods will automatically
  # use this information (i.e. the skin code and the shared secret) if it is available. 
  # Otherwise, you have to provide it yourself for every method call you make. See
  # {Adyen::Form.register_skin} for more information.
  #
  # @see Adyen::Form.register_skin
  # @see Adyen::Form.hidden_fields
  # @see Adyen::Form.redirect_url
  # @see Adyen::Form.redirect_signature_check
  module Form

    extend ActionView::Helpers::TagHelper

    ######################################################
    # SKINS
    ######################################################

    # Returns all registered skins and their accompanying skin code and shared secret.
    # @return [Hash] The hash of registered skins.
    def self.skins
      @skins ||= {}
    end
    
    # Sets the registered skins.
    # @param [Hash<Symbol, Hash>] hash A hash with the skin name as key and the skin parameter hash 
    #    (which should include +:skin_code+ and +:shared_secret+) as value.
    # @see Adyen::Form.register_skin
    def self.skins=(hash)
      @skins = hash.inject({}) do |skins, (name, skin)|
        skins[name.to_sym] = skin.merge(:name => name.to_sym)
        skins
      end
    end

    # Registers a skin for later use.
    #
    # You can store a skin using a self defined symbol. Once the skin is registered,
    # you can refer to it using this symbol instead of the hard-to-remember skin code.
    # Moreover, the skin's shared_secret will be looked up automatically for calculting
    # signatures.
    #
    # @example
    #   Adyen::Form.register_skin(:my_skin, 'dsfH67PO', 'Dfs*7uUln9')
    # @param [Symbol] name The name of the skin.
    # @param [String] skin_code The skin code for this skin, as defined by Adyen.
    # @param [String] shared_secret The shared secret used for signature calculation.
    # @see Adyen.load_config
    def self.register_skin(name, skin_code, shared_secret)
      self.skins[name.to_sym] = {:name => name.to_sym, :skin_code => skin_code, :shared_secret => shared_secret }
    end

    # Returns skin information given a skin name.
    # @param [Symbol] skin_name The name of the skin
    # @return [Hash, nil] A hash with the skin information, or nil if not found.
    def self.skin_by_name(skin_name)
      self.skins[skin_name.to_sym]
    end

    # Returns skin information given a skin code.
    # @param [String] skin_code The skin code of the skin
    # @return [Hash, nil] A hash with the skin information, or nil if not found.
    def self.skin_by_code(skin_code)
      self.skins.detect { |(name, skin)| skin[:skin_code] == skin_code }.last rescue nil
    end

    # Returns the shared secret belonging to a skin code.
    # @param [String] skin_code The skin code of the skin
    # @return [String, nil] The shared secret for the skin, or nil if not found. 
    def self.lookup_shared_secret(skin_code)
      skin = skin_by_code(skin_code)[:shared_secret] rescue nil
    end

    ######################################################
    # DEFAULT FORM / REDIRECT PARAMETERS
    ######################################################

    # Returns the default parameters to use, unless they are overridden.
    # @see Adyen::Form.default_parameters
    # @return [Hash] The hash of default parameters
    def self.default_parameters
      @default_arguments ||= {}
    end
    
    # Sets the default parameters to use.
    # @see Adyen::Form.default_parameters
    # @param [Hash] hash The hash of default parameters
    def self.default_parameters=(hash)
      @default_arguments = hash
    end

    ######################################################
    # ADYEN FORM URL
    ######################################################

    # The URL of the Adyen payment system that still requires the current
    # Adyen enviroment to be filled in.
    ACTION_URL = "https://%s.adyen.com/hpp/select.shtml"

    # Returns the URL of the Adyen payment system, adjusted for an Adyen environment.
    #
    # @param [String] environment The Adyen environment to use. This parameter can be 
    #    left out, in which case the 'current' environment will be used.
    # @return [String] The absolute URL of the Adyen payment system that can be used
    #    for payment forms or redirects.
    # @see Adyen::Form.environment
    # @see Adyen::Form.redirect_url
    def self.url(environment = nil)
      environment ||= Adyen.environment
      Adyen::Form::ACTION_URL % environment.to_s
    end

    ######################################################
    # POSTING/REDIRECTING TO ADYEN
    ######################################################

    # Transforms the payment parameters hash to be in the correct format.
    # It will also include the default_parameters hash. Finally, switches 
    # the +:skin+ parameter out for the +:skin_code+ and +:shared_secret+ 
    # parameter using the list of registered skins. 
    #
    # @private
    # @param [Hash] parameters The payment parameters hash to transform
    def self.do_parameter_transformations!(parameters = {})
      raise "YENs are not yet supported!" if parameters[:currency_code] == 'JPY' # TODO: fixme

      parameters.replace(default_parameters.merge(parameters))
      parameters[:recurring_contract] = 'RECURRING' if parameters.delete(:recurring) == true
      parameters[:order_data]         = Adyen::Encoding.gzip_base64(parameters.delete(:order_data_raw)) if parameters[:order_data_raw]
      parameters[:ship_before_date]   = Adyen::Formatter::DateTime.fmt_date(parameters[:ship_before_date])
      parameters[:session_validity]   = Adyen::Formatter::DateTime.fmt_time(parameters[:session_validity])
      
      if parameters[:skin]
        skin = Adyen::Form.skin_by_name(parameters.delete(:skin))
        parameters[:skin_code]     ||= skin[:skin_code]
        parameters[:shared_secret] ||= skin[:shared_secret]
      end
    end

    # Transforms the payment parameters to be in the correct format and calculates the merchant
    # signature parameter. It also does some basic health checks on the parameters hash.
    #
    # @param [Hash] parameters The payment parameters. The parameters set in the 
    #    {Adyen::Form.default_parameters} hash will be included automatically.
    # @param [String] shared_secret The shared secret that should be used to calculate
    #    the payment request signature. This parameter can be left if the skin that is
    #    used is registered (see {Adyen::Form.register_skin}), or if the shared secret 
    #    is provided as the +:shared_secret+ parameter.
    # @return [Hash] The payment parameters with the +:merchant_signature+ parameter set.
    # @raise [StandardError] Thrown if some parameter health check fails.
    def self.payment_parameters(parameters = {}, shared_secret = nil)
      do_parameter_transformations!(parameters)
      
      raise "Cannot generate form: :currency code attribute not found!"         unless parameters[:currency_code]
      raise "Cannot generate form: :payment_amount code attribute not found!"   unless parameters[:payment_amount]
      raise "Cannot generate form: :merchant_account attribute not found!"      unless parameters[:merchant_account]
      raise "Cannot generate form: :skin_code attribute not found!"             unless parameters[:skin_code]

      # Calculate the merchant signature using the shared secret.
      shared_secret ||= parameters.delete(:shared_secret)
      raise "Cannot calculate payment request signature without shared secret!" unless shared_secret
      parameters[:merchant_sig] = calculate_signature(parameters, shared_secret)
      
      return parameters
    end
    
    # Returns an absolute URL to the Adyen payment system, with the payment parameters included
    # as GET parameters in the URL. The URL also depends on the current Adyen enviroment.
    #
    # The payment parameters that are provided to this method will be merged with the 
    # {Adyen::Form.default_parameters} hash. The default parameter values will be overrided
    # if another value is provided to this method.
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
    def self.redirect_url(parameters = {})
      self.url + '?' + payment_parameters(parameters).map { |(k, v)| 
        "#{k.to_s.camelize(:lower)}=#{CGI.escape(v.to_s)}" }.join('&')
    end
    
    # Returns a HTML snippet of hidden INPUT tags with the provided payment parameters. 
    # The snippet can be included in a payment form that POSTs to the Adyen payment system.
    #
    # The payment parameters that are provided to this method will be merged with the 
    # {Adyen::Form.default_parameters} hash. The default parameter values will be overrided
    # if another value is provided to this method.
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
    def self.hidden_fields(parameters = {})
      
      # Generate a hidden input tag per parameter, join them by newlines.
      payment_parameters(parameters).map { |key, value|
        self.tag(:input, :type => 'hidden', :name => key.to_s.camelize(:lower), :value => value)
      }.join("\n")
    end
    
    ######################################################
    # MERCHANT SIGNATURE CALCULATION
    ######################################################

    # Generates the string that is used to calculate the request signature. This signature
    # is used by Adyen to check whether the request is genuinely originating from you.
    # @param [Hash] parameters The parameters that will be included in the payment request.
    # @return [String] The string for which the siganture is calculated.
    def self.calculate_signature_string(parameters)
      merchant_sig_string = ""
      merchant_sig_string << parameters[:payment_amount].to_s    << parameters[:currency_code].to_s      <<
                             parameters[:ship_before_date].to_s  << parameters[:merchant_reference].to_s <<
                             parameters[:skin_code].to_s         << parameters[:merchant_account].to_s   <<
                             parameters[:session_validity].to_s  << parameters[:shopper_email].to_s      <<
                             parameters[:shopper_reference].to_s << parameters[:recurring_contract].to_s <<
                             parameters[:allowed_methods].to_s   << parameters[:blocked_methods].to_s    <<
                             parameters[:shopper_statement].to_s << parameters[:billing_address_type].to_s
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
    def self.calculate_signature(parameters, shared_secret = nil)
      shared_secret ||= parameters.delete(:shared_secret)
      Adyen::Encoding.hmac_base64(shared_secret, calculate_signature_string(parameters))
    end

    ######################################################
    # REDIRECT SIGNATURE CHECKING
    ######################################################

    # Generates the string for which the redirect signature is calculated, using the request paramaters.
    # @param [Hash] params A hash of HTTP GET parameters for the redirect request.
    # @return [String] The signature string.
    def self.redirect_signature_string(params)
      params[:authResult].to_s + params[:pspReference].to_s + params[:merchantReference].to_s + params[:skinCode].to_s
    end
    
    # Computes the redirect signature using the request parameters, so that the 
    # redirect can be checked for forgery.
    #
    # @param [Hash] params A hash of HTTP GET parameters for the redirect request.
    # @param [String] shared_secret The shared secret for the Adyen skin that was used for
    #     the original payment form. You can leave this out of the skin is registered 
    #     using the {Adyen::Form.register_skin} method.
    # @return [String] The redirect signature
    def self.redirect_signature(params, shared_secret = nil)
      shared_secret ||= lookup_shared_secret(params[:skinCode])
      Adyen::Encoding.hmac_base64(shared_secret, redirect_signature_string(params))
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
    #     using the {Adyen::Form.register_skin} method.
    # @return [true, false] Returns true only if the signature in the parameters is correct.
    def self.redirect_signature_check(params, shared_secret = nil)
      params[:merchantSig] == redirect_signature(params, shared_secret)
    end
  end
end
