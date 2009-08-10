require 'activerecord'

module Adyen
  class Notification < ActiveRecord::Base
    
    DEFAULT_TABLE_NAME = :adyen_payment_notifications
    set_table_name(DEFAULT_TABLE_NAME)
    
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
    
    def authorisation?
      event_code == 'AUTHORISATION'
    end
    
    alias :authorization? :authorisation?
    
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
    
    class Migration < ActiveRecord::Migration
    
      def self.up(table_name = Adyen::Notification::DEFAULT_TABLE_NAME)
        create_table(table_name) do |t|      
          t.boolean  :live,                  :null => false
          t.string   :event_code,            :null => false
          t.string   :psp_reference,         :null => false
          t.string   :original_reference,    :null => true
          t.string   :merchant_reference,    :null => false
          t.string   :merchant_account_code, :null => false
          t.datetime :event_date,            :null => false
          t.boolean  :success,               :null => false
          t.string   :payment_method,        :null => false
          t.string   :operations,            :null => false
          t.text     :reason
          t.string   :currency,              :null => false, :limit => 3
          t.decimal  :value,                 :null => false, :precision => 9, :scale => 2
          t.boolean  :processed,             :default => false, :null => false
          t.timestamps
        end        
      end
      
      def self.down(table_name = Adyen::Notification::DEFAULT_TABLE_NAME)
        drop_table(table_name)
      end
      
    end
    
  end
end