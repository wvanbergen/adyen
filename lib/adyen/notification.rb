require 'activerecord'

module Adyen
  class Notification < ActiveRecord::Base

    DEFAULT_TABLE_NAME = :adyen_notifications
    set_table_name(DEFAULT_TABLE_NAME)

    validates_presence_of :event_code
    validates_presence_of :psp_reference
    validates_uniqueness_of :success, :scope => [:psp_reference, :event_code]

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

    def collect_payment_for_recurring_contract!(options)
      # Make sure we convert the value to cents
      options[:value] = Adyen::Formatter::Price.in_cents(options[:value])
      raise "This is not a recurring contract!" unless event_code == 'RECURRING_CONTRACT'
      Adyen::SOAP::RecurringService.submit(options.merge(:recurring_reference => self.psp_reference))
    end

    def deactivate_recurring_contract!(options)
      raise "This is not a recurring contract!" unless event_code == 'RECURRING_CONTRACT'
      Adyen::SOAP::RecurringService.deactivate(options.merge(:recurring_reference => self.psp_reference))
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
        self.write_attribute(:value, Adyen::Formatter::Price.from_cents(value)) unless value.blank?
      end
    end

    class Migration < ActiveRecord::Migration

      def self.up(table_name = Adyen::Notification::DEFAULT_TABLE_NAME)
        create_table(table_name) do |t|
          t.boolean  :live,                  :null => false, :default => false
          t.string   :event_code,            :null => false
          t.string   :psp_reference,         :null => false
          t.string   :original_reference,    :null => true
          t.string   :merchant_reference,    :null => false
          t.string   :merchant_account_code, :null => false
          t.datetime :event_date,            :null => false
          t.boolean  :success,               :null => false, :default => false
          t.string   :payment_method,        :null => true
          t.string   :operations,            :null => true
          t.text     :reason
          t.string   :currency,              :null => false, :limit => 3
          t.decimal  :value,                 :null => true, :precision => 9, :scale => 2
          t.boolean  :processed,             :null => false, :default => false
          t.timestamps
        end
        add_index table_name, [:psp_reference, :event_code, :success], :unique => true, :name => 'adyen_notification_uniqueness'
      end

      def self.down(table_name = Adyen::Notification::DEFAULT_TABLE_NAME)
        remove_index(table_name, :name => 'adyen_notification_uniqueness')
        drop_table(table_name)
      end
    end
  end
end