require 'activerecord'

module Adyen
  class Notification # < ActiveRecord::Base

    attr_accessor :live, :event_code, :psp_reference, :original_reference, :merchant_reference,
      :merchant_account_code, :event_date, :success, :payment_method, :operations, :reason,
      :currency, :value

    alias :event :event_code
    alias :event= :event_code=

    def initialize(params)
      params.each do |key, value|
        method = "#{key.to_s.underscore}=".to_sym
        send(method, value) if self.respond_to?(method)
      end
    end
    
    def live?
      self.live
    end
    
    def success?
      self.success
    end
    
    def successful_authorisation?
      event_code == :authorisation && success?
    end
    
    alias :successful_authorization? :successful_authorisation?
    
    
    class HttpPost < Notification

      def initialize(request)
        super(request.params)
      end

      def value=(value)
        @value = Adyen::Price.from_cents(value)
      end

      def live=(value)
        @live = [true, 1, '1', 'true'].include?(value)
      end

      def success=(value)
        @success = [true, 1, '1', 'true'].include?(value)
      end 

      def event_code=(value)
        @event_code = value.to_s.downcase.to_sym
      end

      def operations=(value)
        @operations = value.split(',').map { |o| o.downcase.to_sym }
      end
    end    
    
  end
end
