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
        if String === subject
          XML::HTMLParser.string(subject).parse
        elsif document.respond_to?(:body)
          XML::HTMLParser.string(subject.body).parse
        elsif XML::Node === subject
          subject
        elsif XML::Document === subject
          subject
        else
          raise "Cannot handle this XML input type"
        end
      end

      def self.check(subject, checks = {})
        document(subject).find_first(build_xpath_query(checks))
      end      
    end
    
    class HaveAdyenPaymentForm
  
      def initialize(checks)
        @checks = checks
      end
    
      def matches?(document)
        Adyen::Matchers::XPathCheck.check(document, @checks)
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
    
    
    def assert_adyen_payment_form(subject, checks = {})
      default_checks = {:merchant_sig => :anything, :order_data => :anything }
      XPathCheck.check(subject, default_checks.merge(checks))
    end
    
    def assert_adyen_recurring_payment_form(subject, recurring_checks = {})
      recurring_checks = { :recurring => true, :shopper_email => :anything, :shopper_reference => :anything }
      assert_adyen_payment_form(subject, recurring_checks.merge(checks))
    end           

    def assert_adyen_single_payment_form(subject, recurring_checks = {})
      recurring_checks = { :recurring => false }
      assert_adyen_payment_form(subject, recurring_checks.merge(checks))
    end    
    
  end
end
