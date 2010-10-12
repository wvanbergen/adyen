require 'adyen/api/simple_soap_client'
require 'adyen/api/payment_service'
require 'adyen/api/recurring_service'

module Adyen
  # The API module contains classes that interact with the Adyen SOAP API.
  #
  # You'll need to provide a username and password to interact with Adyen:
  #
  #     Adyen::API.username = 'ws@Company.MyAccount'
  #     Adyen::API.password = 'secret'
  #
  # Furthermore, you can setup default parameters, that will be used by every
  # API call, by using {Adyen::API.default_arguments}.
  #
  # The following classes, which handle the SOAP services, are available:
  #
  # * {PaymentService}   - for authorisation of, and modification to, payments.
  # * {RecurringService} - for handling recurring contract details.
  #
  # *However*, direct use of these classes is discouraged in favor of the
  # shortcut methods defined on the API module.
  #
  # Note that you'll need an Adyen notification PSP reference for some of the
  # calls. Because of this, store all notifications that Adyen sends to you.
  # (e.g. using the {Adyen::Notification} ActiveRecord class). Moreover, these
  # calls do *not* tell you whether or not the requested action was successful.
  # For this you will have to check the notification that will be sent.
  #
  # = Authorising payments
  #
  # To authorise payments, not recurring ones, the customers payment details
  # will have to pass through your application and infrastucture. Because of
  # this you will have to contact Adyen and provide the necessary paperwork
  # which says that you’re PCI DSS compliant.
  #
  # Unless you are going to process over twenty thousand payments anually, the
  # PCI DSS Self-Assessment Questionnaire (SAQ) type A will probably suffice.
  #
  # @see http://en.wikipedia.org/wiki/Payment_Card_Industry_Data_Security_Standard
  # @see https://www.pcisecuritystandards.org/saq/instructions_dss.shtml
  module API
    class << self
      # The username that’s used to authenticate for the Adyen SOAP services.
      # It should look something like +ws@Company.MyAccount+
      # @return [String]
      attr_accessor :username

      # The password that’s used to authenticate for the Adyen SOAP services.
      # You can configure it in the user management tool of the merchant area.
      # @return [String]
      attr_accessor :password

      # Default arguments that will be used for every API call. For instance:
      #
      #   Adyen::API.default_arguments[:merchant_account] = 'MyMerchant'
      #
      # You can override these default values by passing a diffferent value for
      # the named parameter to the service class constructor.
      #
      # @return [Hash]
      attr_accessor :default_params
      @default_params = {}

      def authorise_payment(params)
        PaymentService.new(params).authorise_payment
      end

      def authorise_recurring_payment(params)
        PaymentService.new(params).authorise_recurring_payment
      end

      def authorise_one_click_payment(params)
        PaymentService.new(params).authorise_one_click_payment
      end

      def capture_payment(psp_reference, currency, value)
        PaymentService.new({
          :psp_reference => psp_reference,
          :amount => { :currency => currency, :value => value }
        }).capture
      end

      def refund_payment(psp_reference, currency, value)
        PaymentService.new({
          :psp_reference => psp_reference,
          :amount => { :currency => currency, :value => value }
        }).refund
      end

      def cancel_or_refund_payment(psp_reference)
        PaymentService.new(:psp_reference => psp_reference).cancel_or_refund
      end

      def cancel_payment(psp_reference)
        PaymentService.new(:psp_reference => psp_reference).cancel
      end

      def list_recurring_details(shopper_reference)
        RecurringService.new(:shopper => { :reference => shopper_reference }).list
      end

      def disable_recurring_contract(shopper_reference, recurring_detail_reference = nil)
        RecurringService.new({
          :shopper => { :reference => shopper_reference },
          :recurring_detail_reference => recurring_detail_reference
        }).disable
      end
    end
  end
end
