require "handsoap"

module Adyen
  module SOAP

    class << self 
      attr_accessor :username, :password, :default_arguments
    end

    self.default_arguments = {}
    
    class Base < Handsoap::Service

      def on_after_create_http_client(http_client) 
        puts "Setting username and password"
        http_client.userpwd = "#{Adyen::SOAP.username}:#{Adyen::SOAP.password}"
      end
      
    end
    
    class RecurringService < Base
      
      RECURRING_WSDL_URI     = 'https://pal-%s.adyen.com/pal/Recurring.wsdl'
      RECURRING_ENDPOINT_URI = 'https://pal-%s.adyen.com/pal/servlet/soap/Recurring'
          
      def self.endpoint_uri(environment = nil)
        RECURRING_ENDPOINT_URI % (environment || Adyen.autodetect_environment)
      end
      
      def self.wsdl_uri(environment = nil)
        RECURRING_WSDL_URI % (environment || Adyen.autodetect_environment)
      end
      
      endpoint :uri => endpoint_uri, :version => 1
      
      
      def on_create_document(doc)
        doc.alias 'ns1', 'http://recurring.services.adyen.com'
        doc.alias 'ns2', 'http://payment.services.adyen.com'
        doc.alias 'ns3', 'http://common.services.adyen.com'
      end
      
      def on_response_document(doc)
        doc.add_namespace 'ns1', 'http://recurring.services.adyen.com'
        doc.add_namespace 'ns2', 'http://payment.services.adyen.com'                
        doc.add_namespace 'ns3', 'http://common.services.adyen.com'        
      end     
      
      def submit(args = {})
        invoke_args = Adyen::SOAP.default_arguments.merge(args)
        
        response = invoke('ns1:submitRecurring') do |message|
          message.add('ns1:recurringRequest') do |req|
            req.add('ns1:amount') do |amount|
              amount.add('ns3:currency', invoke_args[:currency])
              amount.add('ns3:value', invoke_args[:value])  
            end
            req.add('ns1:merchantAccount', invoke_args[:merchant_account])   
            req.add('ns1:recurringReference', invoke_args[:recurring_reference])
            req.add('ns1:reference', invoke_args[:reference])
            req.add('ns1:shopperEmail', invoke_args[:shopper_email])
            req.add('ns1:shopperReference', invoke_args[:shopper_reference])             
          end
        end
      end
      
      def deactivate(args = {})
        invoke_args = Adyen::SOAP.default_arguments.merge(args)        
        response = invoke('ns1:deactivateRecurring') do |message|
          message.add('ns1:recurringRequest') do |req|          
            req.add('ns1:merchantAccount', invoke_args[:merchant_account])   
            req.add('ns1:recurringReference', invoke_args[:recurring_reference])
            req.add('ns1:reference', invoke_args[:reference])
            req.add('ns1:shopperReference', invoke_args[:shopper_reference])          
          end
        end
      end
    end
  end  
end
