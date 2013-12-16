require 'adyen/api/xml_querier'

module Adyen
  module Matchers

    module XPathPaymentFormCheck

      def self.build_xpath_query(checks)
        # Start by finding the check for the Adyen form tag
        xpath_query =  "//form[@action='#{Adyen::Form.url}']"

        # Add recurring/single check if specified
        recurring =  checks.delete(:recurring)
        unless recurring.nil?
          if recurring
            xpath_query << "[descendant::input[@type='hidden'][@name='recurringContract']]"
          else
            xpath_query << "[not(descendant::input[@type='hidden'][@name='recurringContract'])]"
          end
        end

        # Add a check for all the other fields specified
        checks.each do |key, value|
          condition  = "descendant::input[@type='hidden'][@name='#{Adyen::Form.camelize(key)}']"
          condition << "[@value='#{value}']" unless value == :anything
          xpath_query << "[#{condition}]"
        end

        return xpath_query
      end

      def self.check(subject, checks = {})
        found = false
        document = Adyen::API::XMLQuerier.html(subject)
        document.xpath(build_xpath_query(checks)) do |result|
          found = true
        end
        return found
      end
    end

    class HaveAdyenPaymentForm

      def initialize(checks)
        @checks = checks
      end

      def matches?(document)
        Adyen::Matchers::XPathPaymentFormCheck.check(document, @checks)
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
      default_checks = {:merchant_sig => :anything, :payment_amount => :anything, :currency_code => :anything, :skin_code => :anything }
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
      default_checks = {:merchant_sig => :anything, :payment_amount => :anything, :currency_code => :anything, :skin_code => :anything }
      assert Adyen::Matchers::XPathPaymentFormCheck.check(subject, default_checks.merge(checks)), 'No Adyen payment form found'
    end

    def assert_adyen_recurring_payment_form(subject, checks = {})
      recurring_checks = { :recurring => true, :shopper_email => :anything, :shopper_reference => :anything }
      assert_adyen_payment_form(subject, recurring_checks.merge(checks))
    end

    def assert_adyen_single_payment_form(subject, checks = {})
      recurring_checks = { :recurring => false }
      assert_adyen_payment_form(subject, recurring_checks.merge(checks))
    end

  end
end
