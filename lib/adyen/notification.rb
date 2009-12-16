require 'active_record'

module Adyen
  
  # The +Adyen::Notification+ class handles notifications sent by Adyen to your servers.
  #
  # Because notifications contain important payment status information, you should store
  # these notifications in your database. For this reason, +Adyen::Notification+ inherits
  # from +ActiveRecord::Base+, and a migration is included to simply create a suitable table
  # to store the notifications in.
  #
  # Adyen can either send notifications to you via HTTP POST requests, or SOAP requests.
  # Because SOAP is not really well supported in Rails and setting up a SOAP server is
  # not trivial, only handling HTTP POST notifications is currently supported.
  #
  # @example
  #    @notification = Adyen::Notification::HttpPost.log(request)
  #    if @notification.successful_authorisation?
  #      @invoice = Invoice.find(@notification.merchant_reference)
  #      @invoice.set_paid!
  #    end
  #
  # @see Adyen::Notification::HttpPost.log
  class Notification < ActiveRecord::Base

    # The default table name to use for the notifications table.
    DEFAULT_TABLE_NAME = :adyen_notifications
    set_table_name(DEFAULT_TABLE_NAME)

    # A notification should always include an event_code
    validates_presence_of :event_code
    
    # A notification should always include a psp_reference
    validates_presence_of :psp_reference
    
    # A notification should be unique using the composed key of
    # [:psp_reference, :event_code, :success]
    validates_uniqueness_of :success, :scope => [:psp_reference, :event_code]

    # Make sure we don't end up with an original_reference with an empty string
    before_validation { |notification| notification.original_reference = nil if notification.original_reference.blank? }

    # Logs an incoming notification into the database.
    #
    # @param [Hash] params The notification parameters that should be stored in the database.
    # @return [Adyen::Notification] The initiated and persisted notification instance.
    # @raise This method will raise an exception if the notification cannot be stored.
    # @see Adyen::Notification::HttpPost.log
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

    # Returns true if this notification is an AUTHORISATION notification
    # @return [true, false] true iff event_code == 'AUTHORISATION'
    # @see Adyen.notification#successful_authorisation?
    def authorisation?
      event_code == 'AUTHORISATION'
    end

    alias :authorization? :authorisation?

    # Returns true if this notification is an AUTHORISATION notification and
    # the success status indicates that the authorization was successfull.
    # @return [true, false] true iff  the notification is an authorization
    #   and the authorization was successful according to the success field.
    def successful_authorisation?
      event_code == 'AUTHORISATION' && success?
    end
    
    alias :successful_authorization? :successful_authorisation?

    # Collect a payment using the recurring contract that was initiated with
    # this notification. The payment is collected using a SOAP call to the 
    # Adyen SOAP service for recurring payments.
    # @param [Hash] options The payment parameters.
    # @see Adyen::SOAP::RecurringService#submit
    def collect_payment_for_recurring_contract!(options)
      # Make sure we convert the value to cents
      options[:value] = Adyen::Formatter::Price.in_cents(options[:value])
      raise "This is not a recurring contract!" unless event_code == 'RECURRING_CONTRACT'
      Adyen::SOAP::RecurringService.submit(options.merge(:recurring_reference => self.psp_reference))
    end

    # Deactivates the recurring contract that was initiated with this notification.
    # The contract is deactivated by sending a SOAP call to the Adyen SOAP service for
    # recurring contracts.
    # @param [Hash] options The recurring contract parameters.
    # @see Adyen::SOAP::RecurringService#deactivate
    def deactivate_recurring_contract!(options)
      raise "This is not a recurring contract!" unless event_code == 'RECURRING_CONTRACT'
      Adyen::SOAP::RecurringService.deactivate(options.merge(:recurring_reference => self.psp_reference))
    end

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

    # An ActiveRecord migration that can be used to create a suitable table  
    # to store Adyen::Notification instances for your application.
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