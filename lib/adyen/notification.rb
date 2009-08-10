require 'activerecord'

module Adyen
  class Notification < ActiveRecord::Base
    set_table_name :adyen_payment_notifications
    
    # Make sure we don't end up with an original_reference with an empty string
    before_validation { |notification| notification.original_reference = nil if notification.original_reference.blank? }

    def self.log(params)
      converted_params = {}
      # Convert each attribute from CamelCase notation to under_score notation
      # For example, merchantReference will be converted to merchant_reference
      params.each do |key, value| 
        field_name                   = key.to_s.underscore
        converted_params[field_name] = value if self.column_names.include?(field_name)
      end
      self.create!(converted_params)
    end
    
    def successful_authorisation?
      event_code == 'AUTHORISATION' && success?
    end
    
    alias :successful_authorization? :successful_authorisation?
    
    class HttpPost < Notification

      def self.log(request)
        super(request.params)
      end

      def live=(value)
        self.write_attribute(:live, [true, 1, '1', 'true'].include?(value)) 
      end

      def success=(value)
        self.write_attribute(:success, [true, 1, '1', 'true'].include?(value)) 
      end 
      
      def value=(value)
        self.write_attribute(:value, Adyen::Price.from_cents(value))
      end
    end    
  end
end