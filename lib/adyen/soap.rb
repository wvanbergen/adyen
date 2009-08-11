require "handsoap"

module Adyen
  module SOAP

    class << self 
      attr_accessor :username, :password, :default_arguments
    end

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
    class RecurringService < Base
      
      ENDPOINT_URI = 'https://pal-%s.adyen.com/pal/servlet/soap/Recurring'
      
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
