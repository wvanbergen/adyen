require 'action_view'

module Adyen
  module Form

    extend ActionView::Helpers::TagHelper

    ACTION_URL = "https://%s.adyen.com/hpp/select.shtml"

    def self.url(environment = nil)
      environment ||= Adyen.environment(environment)
      Adyen::Form::ACTION_URL % environment.to_s
    end

    def self.calculate_signature_string(attributes)
      merchant_sig_string = ""
      merchant_sig_string << attributes[:payment_amount].to_s    << attributes[:currency_code].to_s      <<
                             attributes[:ship_before_date].to_s  << attributes[:merchant_reference].to_s <<
                             attributes[:skin_code].to_s         << attributes[:merchant_account].to_s   <<
                             attributes[:session_validity].to_s  << attributes[:shopper_email].to_s      <<
                             attributes[:shopper_reference].to_s << attributes[:recurring_contract].to_s <<
                             attributes[:allowed_methods].to_s   << attributes[:blocked_methods].to_s    <<
                             attributes[:shopper_statement].to_s << attributes[:billing_address_type].to_s
    end

    def self.calculate_signature(attributes)
       Adyen::Encoding.hmac_base64(attributes.delete(:shared_secret), calculate_signature_string(attributes))
    end

    def self.do_attribute_transformations!(attributes = {})
      raise "YENs are not yet supported!" if attributes[:currency_code] == 'JPY' # TODO: fixme

      attributes[:recurring_contract] = 'DEFAULT' if attributes.delete(:recurring) == true
      attributes[:order_data]         = Adyen::Encoding.gzip_base64(attributes.delete(:order_data_raw)) if attributes[:order_data_raw]
      attributes[:ship_before_date]   = Adyen::Formatter::DateTime.fmt_date(attributes[:ship_before_date])
      attributes[:session_validity]   = Adyen::Formatter::DateTime.fmt_time(attributes[:session_validity])
    end

    def self.payment_fields(attributes = {})
      do_attribute_transformations!(attributes)
      
      raise "Cannot generate form: :currency code attribute not found!"         unless attributes[:currency_code]
      raise "Cannot generate form: :payment_amount code attribute not found!"   unless attributes[:payment_amount]
      raise "Cannot generate form: :merchant_account attribute not found!"      unless attributes[:merchant_account]
      raise "Cannot generate form: :skin_code attribute not found!"             unless attributes[:skin_code]
      raise "Cannot generate form: :shared_secret signing secret not provided!" unless attributes[:shared_secret]

      # Merchant signature
      attributes[:merchant_sig] = calculate_signature(attributes)
      return attributes      
    end
    
    def self.redirect_url(attributes)
      self.url + '?' + payment_fields(attributes).map { |(k, v)| "#{k.to_s.camelize(:lower)}=#{CGI.escape(v.to_s)}" }.join('&')
    end

    def self.hidden_fields(attributes = {})
      # Generate hidden input tags
      payment_fields(attributes).map { |key, value|
        self.tag(:input, :type => 'hidden', :name => key.to_s.camelize(:lower), :value => value)
      }.join("\n")
    end

    def self.redirect_signature_string(params)
      params[:authResult].to_s + params[:pspReference].to_s + params[:merchantReference].to_s + params[:skinCode].to_s
    end

    def self.redirect_signature(params, shared_secret)
      Adyen::Encoding.hmac_base64(shared_secret, redirect_signature_string(params))
    end

    def self.redirect_signature_check(params, shared_secret)
      params[:merchantSig] == redirect_signature(params, shared_secret)
    end

  end
end