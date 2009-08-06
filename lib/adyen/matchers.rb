module Adyen
  module Matchers 
    
    module XPathCheck
      
      def self.build_xpath_query(checks)
        xpath_query =  "//form[@action='#{AdyenPaymentIntegrator::Form.url}']" # Adyen form 

        recurring =  checks.delete(:recurring)
        unless recurring.nil?
          if recurring
            xpath_query << "[descendant::input[@type='hidden'][@name='recurringContract']]"          
          else
            xpath_query << "[not(descendant::input[@type='hidden'][@name='recurringContract'])]"
          end
        end

        checks.each do |key, value|
          condition  = "descendant::input[@type='hidden'][@name='#{key.to_s.camelize(:lower)}']"
          condition << "[@value='#{value}']" unless value == :anything
          xpath_query << "[#{condition}]"
        end 
        
        return xpath_query       
      end

      def self.document(subject)
        case subject
        when 
          
        else
          return 
        end
      end

      def self.check(subject, checks = {})
        document = document(subject)
        XML::HTMLParser.string(document).parse.find_first(build_xpath_query(@checks))        
      end      
    end
    
    class HaveAdyenPaymentForm
  
      def initialize(checks)
        @checks = checks
      end
      
      def build_xpath_query(checks)
        xpath_query =  "//form[@action='#{AdyenPaymentIntegrator::Form.url}']" # Adyen form 

        recurring =  checks.delete(:recurring)
        unless recurring.nil?
          if recurring
            xpath_query << "[descendant::input[@type='hidden'][@name='recurringContract']]"          
          else
            xpath_query << "[not(descendant::input[@type='hidden'][@name='recurringContract'])]"
          end
        end

        checks.each do |key, value|
          condition  = "descendant::input[@type='hidden'][@name='#{key.to_s.camelize(:lower)}']"
          condition << "[@value='#{value}']" unless value == :anything
          xpath_query << "[#{condition}]"
        end 
        
        return xpath_query       
      end
    
      def matches?(document)
        document = document.body if document.respond_to?(:body)
        XML::HTMLParser.string(document).parse.find_first(build_xpath_query(@checks))
      end
  
      def description
        "have an adyen payment form"
      end
  
      def failure_message
        "expected to find a valid Adyen form on this page"
      end
  
      def negative_failure_message
        "expected not to find a valid Adyen form on this page"
      end
    end

    def have_adyen_payment_form(checks = {})
      default_checks = {:merchant_sig => :anything, :order_data => :anything }
      HaveAdyenPaymentForm.new(default_checks.merge(checks))
    end
    
    def have_adyen_recurring_payment_form(checks = {})
      recurring_checks = { :recurring => true, :shopper_email => :anything, :shopper_reference => :anything }
      have_adyen_payment_form(recurring_checks.merge(checks))
    end 
    
    def have_adyen_single_payment_form(checks = {})
      recurring_checks = { :recurring => false }
      have_adyen_payment_form(recurring_checks.merge(checks))
    end       
  end
end
