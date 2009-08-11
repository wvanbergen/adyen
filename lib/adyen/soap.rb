require "handsoap"

module Adyen
  
  # The SOAP module contains classes that interact with the Adyen
  # SOAP services. The clients are based on the Handsoap library.
  # Shared functionality for all services is implemented in the
  # Adyen::SOAP::Base class.
  #
  # Note that you'll need an Adyen notification PSP reference for
  # most SOAP calls. Because of this, store all notifications that
  # Adyen sends to you. (e.g. using the Adyen::Notification ActiveRecord 
  # class). Moreover, most SOAP calls do not respond that they were
  # successful immediately, but a notifications to indicate that will
  # be sent later on.
  #  
  # You'll need to provide a username and password to interact
  # with the Adyen SOAP services:
  #
  #     Adyen::SOAP.username = 'ws@Company.MyAccount'
  #     Adyen::SOAP.password = 'very$ecret'
  #
  # You can setup default values for every SOAP call that needs them:
  #
  #     Adyen::SOAP.default_arguments[:merchent_account] = 'MyMerchant'
  #
  # For now, only the recurring payment service client is implemented 
  # (Adyen::SOAP::RecurringService). 
  module SOAP

    class << self 
      # Set up accessors for HTTP Basic Authentication and
      # for adding default arguments to SOAP calls.
      attr_accessor :username, :password, :default_arguments
    end

    # Use no default arguments by default
    self.default_arguments = {}
    
    # The base class sets up XML namespaces and HTTP authentication
    # for all the Adyen SOAP services
    class Base < Handsoap::Service

      def self.inherited(klass)
        # The version must be set to construct the request envelopes,
        # the URI wil be set later using the correct Adyen.environment.
        klass.endpoint :version => 1, :uri => 'bogus'
      end

      # Setup basic auth headers in the HTTP client
      def on_after_create_http_client(http_client) 
        debug { |logger| logger.puts "Authorization: #{Adyen::SOAP.username}:#{Adyen::SOAP.password}..." }
        # Handsoap BUG: Setting headers does not work, using a Curb specific method for now.
        # auth = Base64.encode64("#{Adyen::SOAP.username}:#{Adyen::SOAP.password}").chomp
        # http_client.headers['Authorization'] = "Basic #{auth}"
        http_client.userpwd = "#{Adyen::SOAP.username}:#{Adyen::SOAP.password}"
      end
    
      # Setup XML namespaces for SOAP request body
      def on_create_document(doc)    
        doc.alias 'payment',   'http://payment.services.adyen.com'
        doc.alias 'recurring', 'http://recurring.services.adyen.com'
        doc.alias 'common',    'http://common.services.adyen.com'
      end
      
      # Setup XML namespaces for SOAP response
      def on_response_document(doc)
        doc.add_namespace 'payment',   'http://payment.services.adyen.com'
        doc.add_namespace 'recurring', 'http://recurring.services.adyen.com'
        doc.add_namespace 'common',    'http://common.services.adyen.com'        
      end
      
      # Set endpoint URI before dispatch, so that changes in environment
      # are reflected correctly.
      def on_before_dispatch
        self.class.endpoint(:uri => self.class::ENDPOINT_URI % Adyen.environment.to_s, :version => 1)
      end
    end
    
    # SOAP client to interact with the payment modification service of Adyen.
    # At this moment, none of the calls are implemented.
    class PaymentService < Base
    
      ENDPOINT_URI = 'https://pal-%s.adyen.com/pal/servlet/soap/Payment'
          
    end
    
    # SOAP client to interact with the recurring payment service of Adyen.
    # This client implements the submitRecurring call to submit payments
    # for a recurring contract. Moreover, it implements the deactiveRecurring
    # call to cancel a recurring contract.
    #
    # See the Adyen Recurring manual for more information about this SOAP service
    class RecurringService < Base
      
      ENDPOINT_URI = 'https://pal-%s.adyen.com/pal/servlet/soap/Recurring'
      
      # Submits a recurring payment. Requires the following arguments as hash:
      #
      # * <tt>:currency</tt> The currency code (EUR, GBP, USD, etc)
      # * <tt>:value</tt> The value of the payments in cents
      # * <tt>:merchent_account</tt> The merchant account under which to place
      #       this payment.
      # * <tt>:recurring_reference</tt> The psp_reference of the RECURRING_CONTRACT 
      #       notification that was sent after the initial payment.
      # * <tt>:reference</tt> The (merchant) reference for this payment.
      # * <tt>:shopper_email</tt> The email address of the shopper.
      # * <tt>:shopper_reference</tt> The refrence of the shopper. This should be 
      #       the same as the reference that was used to create the recurring contract.
      def submit(args = {})
        invoke_args = Adyen::SOAP.default_arguments.merge(args)
        response = invoke('recurring:submitRecurring') do |message|
          message.add('recurring:recurringRequest') do |req|
            req.add('recurring:amount') do |amount|
              amount.add('common:currency', invoke_args[:currency])
              amount.add('common:value', invoke_args[:value])  
            end
            req.add('recurring:merchantAccount', invoke_args[:merchant_account])   
            req.add('recurring:recurringReference', invoke_args[:recurring_reference])
            req.add('recurring:reference', invoke_args[:reference])
            req.add('recurring:shopperEmail', invoke_args[:shopper_email])
            req.add('recurring:shopperReference', invoke_args[:shopper_reference])             
          end
        end
      end
      
      # Deactivates a recurring payment contract. Requires the following arguments:
      #
      # * <tt>:merchent_account</tt> The merchant account under which to place
      #       this payment.
      # * <tt>:recurring_reference</tt> The psp_reference of the RECURRING_CONTRACT 
      #       notification that was sent after the initial payment.
      # * <tt>:reference</tt> The (merchant) reference for this deactivation.
      # * <tt>:shopper_reference</tt> The refrence of the shopper. This should be 
      #       the same as the reference that was used to create the recurring contract.      
      def deactivate(args = {})
        invoke_args = Adyen::SOAP.default_arguments.merge(args)        
        response = invoke('recurring:deactivateRecurring') do |message|
          message.add('recurring:recurringRequest') do |req|          
            req.add('recurring:merchantAccount', invoke_args[:merchant_account])   
            req.add('recurring:recurringReference', invoke_args[:recurring_reference])
            req.add('recurring:reference', invoke_args[:reference])
            req.add('recurring:shopperReference', invoke_args[:shopper_reference])          
          end
        end
      end
    end
  end  
end
