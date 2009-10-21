require 'action_view'

module Adyen
  module Form

    extend ActionView::Helpers::TagHelper

    ######################################################
    # SKINS
    ######################################################

    def self.skins
      @skins ||= {}
    end
    
    def self.register_skin(name, skin_code, shared_secret)
      self.skins[name] = {:name => name, :skin_code => skin_code, :shared_secret => shared_secret }
    end

    def self.skin_by_name(skin_name)
      self.skins[skin_name]
    end
    
    def self.skin_by_code(skin_code)
      self.skins.detect { |(name, skin)| skin[:skin_code] == skin_code }.last rescue nil      
    end
    
    def self.lookup_shared_secret(skin_code)
      skin = skin_by_code(skin_code)[:shared_secret] rescue nil
    end    
    
    ######################################################
    # DEFAULT FORM / REDIRECT PARAMETERS
    ######################################################    

    def self.default_parameters
      @default_arguments ||= {}
    end
    
    def self.default_parameters=(hash)
      @default_arguments = hash
    end

    ######################################################
    # ADYEN FORM URL
    ######################################################

    ACTION_URL = "https://%s.adyen.com/hpp/select.shtml"

    def self.url(environment = nil)
      environment ||= Adyen.environment(environment)
      Adyen::Form::ACTION_URL % environment.to_s
    end


    ######################################################
    # POSTING/REDIRECTING TO ADYEN
    ######################################################

    def self.do_parameter_transformations!(parameters = {})
      raise "YENs are not yet supported!" if parameters[:currency_code] == 'JPY' # TODO: fixme

      parameters.replace(default_parameters.merge(parameters))
      parameters[:recurring_contract] = 'DEFAULT' if parameters.delete(:recurring) == true
      parameters[:order_data]         = Adyen::Encoding.gzip_base64(parameters.delete(:order_data_raw)) if parameters[:order_data_raw]
      parameters[:ship_before_date]   = Adyen::Formatter::DateTime.fmt_date(parameters[:ship_before_date])
      parameters[:session_validity]   = Adyen::Formatter::DateTime.fmt_time(parameters[:session_validity])
      
      if parameters[:skin]
        skin = Adyen::Form.skin_by_name(parameters.delete(:skin))
        parameters[:skin_code]     ||= skin[:skin_code]
        parameters[:shared_secret] ||= skin[:shared_secret]
      end
    end

    def self.payment_parameters(parameters = {})
      do_parameter_transformations!(parameters)
      
      raise "Cannot generate form: :currency code attribute not found!"         unless parameters[:currency_code]
      raise "Cannot generate form: :payment_amount code attribute not found!"   unless parameters[:payment_amount]
      raise "Cannot generate form: :merchant_account attribute not found!"      unless parameters[:merchant_account]
      raise "Cannot generate form: :skin_code attribute not found!"             unless parameters[:skin_code]
      raise "Cannot generate form: :shared_secret signing secret not provided!" unless parameters[:shared_secret]

      # Merchant signature
      parameters[:merchant_sig] = calculate_signature(parameters)
      return parameters      
    end
    
    def self.redirect_url(parameters = {})
      self.url + '?' + payment_parameters(parameters).map { |(k, v)| "#{k.to_s.camelize(:lower)}=#{CGI.escape(v.to_s)}" }.join('&')
    end

    def self.hidden_fields(parameters = {})
      # Generate hidden input tags
      payment_parameters(parameters).map { |key, value|
        self.tag(:input, :type => 'hidden', :name => key.to_s.camelize(:lower), :value => value)
      }.join("\n")
    end
    
    ######################################################
    # MERCHANT SIGNATURE CALCULATION
    ######################################################

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

    def self.calculate_signature(parameters)
       Adyen::Encoding.hmac_base64(parameters.delete(:shared_secret), calculate_signature_string(parameters))
    end

    ######################################################
    # REDIRECT SIGNATURE CHECKING
    ######################################################

    def self.redirect_signature_string(params)
      params[:authResult].to_s + params[:pspReference].to_s + params[:merchantReference].to_s + params[:skinCode].to_s
    end

    def self.redirect_signature(params, shared_secret = nil)
      shared_secret ||= lookup_shared_secret(params[:skinCode])
      Adyen::Encoding.hmac_base64(shared_secret, redirect_signature_string(params))
    end

    def self.redirect_signature_check(params, shared_secret = nil)
      params[:merchantSig] == redirect_signature(params, shared_secret)
    end

  end
end