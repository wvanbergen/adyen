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

    # Class that handles creating notifications from HTTP Post requests
    class HttpPost < Notification

      def self.log(request)
        super(request.params)
      end

      def live=(value)
        super([true, 1, '1', 'true'].include?(value))
      end

      def success=(value)
        super([true, 1, '1', 'true'].include?(value))
      end
    end
  end
end
