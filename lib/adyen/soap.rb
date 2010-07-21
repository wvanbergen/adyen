begin 
  require "handsoap"
rescue LoadError
  $stderr.puts "The handsoap gem (>= 1.4.1) is required to use the SOAP clients:"
  $stderr.puts "$ (sudo) gem install handsoap --source http://gemcutter.org"
end

module Adyen

  # The SOAP module contains classes that interact with the Adyen SOAP
  # services. The clients are based on the +handsoap+ library and requires at
  # least version 1.4.1 of this gem.
  #
  # Note that you'll need an Adyen notification PSP reference for most SOAP
  # calls. Because of this, store all notifications that Adyen sends to you.
  # (e.g. using the {Adyen::Notification} ActiveRecord class). Moreover, most
  # SOAP calls do not respond that they were successful immediately, but a
  # notifications to indicate that will be sent later on.
  #
  # You'll need to provide a username and password to interact with the Adyen
  # SOAP services:
  #
  #     Adyen::SOAP.username = 'ws@Company.MyAccount'
  #     Adyen::SOAP.password = 'very$ecret'
  #
  # You can setup default parameters that will be used by every SOAP call by
  # using {Adyen::SOAP.default_arguments}. You can override these default
  # values by passing another value as parameter to the actual call.
  #
  #     Adyen::SOAP.default_arguments[:merchant_account] = 'MyMerchant'
  #
  # All SOAP clients are based on the {Adyen::SOAP::Base} class, which sets up
  # the Handsoap library to work with the Adyen SOAP services and implements
  # shared functionality. Based on this class, the following services are available:
  #
  # * {Adyen::SOAP::RecurringService} - SOAP service for handling recurring payments.
  # * {Adyen::SOAP::PaymentService} - SOAP service for modification to payments. Currently, 
  #   this class is just a stub. Feel free to implement it as you need it.
  module SOAP

    class << self
      
      # Username for the HTTP Basic Authentication that Adyen uses. Your username
      # should be something like +ws@Company.MyAccount+
      # @return [String]
      attr_accessor :username
      
      # Password for the HTTP Basic Authentication that Adyen uses. You can choose
      # your password yourself in the user management tool of the merchant area.
      # @return [String] 
      attr_accessor :password
      
      # Default arguments that will be used for every SOAP call.
      # @return [Hash] 
      attr_accessor :default_arguments
    end

    self.default_arguments = {} # Set default value

    # The base class sets up XML namespaces and the HTTP client
    # for all the Adyen SOAP services.
    class Base < Handsoap::Service

      # Basic setup for the SOAP endpoint when creating a subclass.
      #
      # The version must be set to construct the request envelopes, the URI
      # wil be set later using the correct {Adyen.environment} value. For now,
      # use a bogus value so handsoap will not complain.
      def self.inherited(klass) # :nodoc:
        klass.endpoint :version => 1, :uri => 'bogus'
      end

      # Setup some CURL options to handle redirects correctly.
      def on_after_create_http_client(http_client)  # :nodoc:
        http_client.follow_location = true
        http_client.max_redirects   = 2
      end

      # Setup basic authentication for SOAP requests
      # @see Adyen::SOAP.username
      # @see Adyen::SOAP.password
      def on_after_create_http_request(http_request) # :nodoc:
        debug { |logger| logger.puts "Authorization: #{Adyen::SOAP.username}:#{Adyen::SOAP.password}..." }
        http_request.set_auth Adyen::SOAP.username, Adyen::SOAP.password
      end

      # Sets up XML namespaces for composing the SOAP request body.
      def on_create_document(doc) # :nodoc:
        doc.alias 'payment',   'http://payment.services.adyen.com'
        doc.alias 'recurring', 'http://recurring.services.adyen.com'
        doc.alias 'common',    'http://common.services.adyen.com'
      end

      # Sets up the XML namespaces for parsing the SOAP response.
      def on_response_document(doc) # :nodoc:
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

    # SOAP client to interact with the payment modification service of Adyen. This client
    # implements the following calls:
    #
    # * +authorise+ to list recurring contracts for a shopper, using {Adyen::SOAP::PaymentService#authorise}.
    # * +cancelOrRefund+ to cancel a payment (or refund if it has been captured), using 
    #   {Adyen::SOAP::PaymentService#cancel_or_refund}.
    #
    # Before using this service, make sure to set the SOAP username and
    # password (see {Adyen::SOAP.username} and {Adyen::SOAP.password}).
    class PaymentService < Base

      ENDPOINT_URI = 'https://pal-%s.adyen.com/pal/servlet/soap/Payment'

      # Submits a recurring payment for authorisation.
      #
      # @example 
      #   Adyen::SOAP::PaymentService.authorise(
      #     :merchant_account => 'MyAccount', :selected_recurring_detail_reference => 'LATEST',
      #     :shopper_reference => user.id, :shopper_email => user.email,
      #     :reference => invoice.id, :currency => invoice.currency, :value => invoice.amount)
      #
      # @param [Hash] args The paramaters to use for this call. These will be merged by any default
      #       parameters set using {Adyen::SOAP.default_arguments}. Note that every option defined below
      #       is required by the Adyen SOAP service, so please provide a value for all options.
      # @option args [String] :selected_recurring_detail_reference ('LATEST') This is the
      #       recurringDetailReference you want to use for this payment. You can use the
      #       value "LATEST" to select the most recently used recurring detail, which is the default. 
      # @option args [String] :merchant_account The merchant account you want to process this payment
      #       with.
      # @option args [String] :currency The currency code (EUR, GBP, USD, etc).
      # @option args [Integer] :value The value of the payment in cents.
      # @option args [String] :reference Your reference for this payment. This (merchant) reference
      #       will be used in all communication to you about the status of the payment.
      #       Although it is a good idea to make sure it is unique, this is not a requirement.
      # @option args [String] :shopper_email The email address of the shopper. This does not have to
      #       match the email address supplied with the initial payment, since it may have
      #       changed in the mean time.
      # @option args [String] :shopper_reference The reference of the shopper. This should be
      #       the same as the reference that was used to create the recurring contract.
      # @option args [Integer] :fraud_offset (optional) An integer that is added to normal fraud score.
      #       The value can be either positive or negative.
      # @option args [String] :shopper_ip (optional) The IP address of the shopper. Used in various risk
      #       checks (number of payment attempts, location based checks), so it is a good idea to supply
      #       this.
      #
      # @return [nil] This action returns nothing of interest. The result of the authorization 
      #   will be communicated using a {Adyen::Notification notification}.
      #
      # @see https://support.adyen.com/index.php?_m=downloads&_a=viewdownload&downloaditemid=1
      #       The Adyen integration manual
      # @see https://support.adyen.com/index.php?_m=downloads&_a=viewdownload&downloaditemid=7&nav=0,3 
      #       The Adyen recurring payments manual.
      def authorise(args = {})
        invoke_args = Adyen::SOAP.default_arguments.merge(args)
        invoke_args[:selected_recurring_detail_reference] ||= 'LATEST'

        response = invoke('payment:authorise') do |message|
          message.add('payment:paymentRequest') do |req|
            req.add('payment:selectedRecurringDetailReference', invoke_args[:selected_recurring_detail_reference])
            req.add('payment:recurring') do |recurring|
              recurring.add('payment:contract', 'RECURRING')
            end
            req.add('payment:merchantAccount', invoke_args[:merchant_account])
            req.add('payment:amount') do |amount|
              amount.add('common:currency', invoke_args[:currency])
              amount.add('common:value', invoke_args[:value])
            end
            req.add('payment:reference', invoke_args[:reference])
            req.add('payment:shopperEmail', invoke_args[:shopper_email])
            req.add('payment:shopperReference', invoke_args[:shopper_reference])
            req.add('payment:shopperInteraction', 'ContAuth')

            # optional fields
            req.add('payment:fraudOffset', invoke_args[:fraud_offset]) if(invoke_args[:fraud_offset])
            req.add('payment:shopperIP', invoke_args[:shopper_ip]) if(invoke_args[:shopper_ip])
          end
        end

        parse_authorise(response)
      end

      # Submits a direct debit recurring payment.
      #
      # @example 
      #   Adyen::SOAP::PaymentService.directdebit(
      #     :merchant_account => 'MyAccount', :selected_recurring_detail_reference => 'LATEST',
      #     :shopper_reference => user.id, :shopper_email => user.email,
      #     :reference => invoice.id, :currency => invoice.currency, :value => invoice.amount)
      #
      # @param [Hash] args The paramaters to use for this call. These will be merged by any default
      #       parameters set using {Adyen::SOAP.default_arguments}. Note that every option defined below
      #       is required by the Adyen SOAP service, so please provide a value for all options.
      # @option args [String] :selected_recurring_detail_reference ('LATEST') This is the
      #       recurringDetailReference you want to use for this payment. You can use the
      #       value "LATEST" to select the most recently used recurring detail, which is the default. 
      # @option args [String] :merchant_account The merchant account you want to process this payment
      #       with.
      # @option args [String] :currency The currency code (EUR, GBP, USD, etc).
      # @option args [Integer] :value The value of the payment in cents.
      # @option args [String] :reference Your reference for this payment. This (merchant) reference
      #       will be used in all communication to you about the status of the payment.
      #       Although it is a good idea to make sure it is unique, this is not a requirement.
      # @option args [String] :shopper_email The email address of the shopper. This does not have to
      #       match the email address supplied with the initial payment, since it may have
      #       changed in the mean time.
      # @option args [String] :shopper_reference The reference of the shopper. This should be
      #       the same as the reference that was used to create the recurring contract.
      # @option args [String] :shopper_ip (optional) The IP address of the shopper. Used in various risk
      #       checks (number of payment attempts, location based checks), so it is a good idea to supply
      #       this.
      #
      # @return [nil] This action returns nothing of interest. The result of the authorization 
      #   will be communicated using a {Adyen::Notification notification}.
      #
      # @see https://support.adyen.com/index.php?_m=downloads&_a=viewdownload&downloaditemid=1
      #       The Adyen integration manual
      # @see https://support.adyen.com/index.php?_m=downloads&_a=viewdownload&downloaditemid=7&nav=0,3 
      #       The Adyen recurring payments manual.
      def directdebit(args = {})
        invoke_args = Adyen::SOAP.default_arguments.merge(args)
        invoke_args[:selected_recurring_detail_reference] ||= 'LATEST'

        response = invoke('payment:directdebit') do |message|
          message.add('payment:request') do |req|
            req.add('payment:selectedRecurringDetailReference', invoke_args[:selected_recurring_detail_reference])
            req.add('payment:recurring') do |recurring|
              recurring.add('payment:contract', 'RECURRING')
            end
            req.add('payment:merchantAccount', invoke_args[:merchant_account])
            req.add('payment:amount') do |amount|
              amount.add('common:currency', invoke_args[:currency])
              amount.add('common:value', invoke_args[:value])
            end
            req.add('payment:reference', invoke_args[:reference])
            req.add('payment:shopperEmail', invoke_args[:shopper_email])
            req.add('payment:shopperReference', invoke_args[:shopper_reference])
            req.add('payment:shopperInteraction', 'ContAuth')
            req.add('payment:shopperIP', invoke_args[:shopper_ip]) if(invoke_args[:shopper_ip])
          end
        end

        parse_directdebit(response)
      end

      # Capture a payment.
      #
      # @param [Hash] args The paramaters to use for this call. These will be merged by any default
      #   parameters set using {Adyen::SOAP.default_arguments}. Note that every option defined below
      #   is required by the Adyen SOAP service, so please provide a value for all options.
      # @option args [String] :merchant_account The merchant account to file this payment under.
      # @option args [String] :currency The currency code (EUR, GBP, USD, etc).
      # @option args [Integer] :value The value of the payment in cents.
      # @option args [String] :original_reference The psp_reference of the payment to capture.
      #
      # @return [nil] This action returns nothing of interest.
      #
      # @see https://support.adyen.com/index.php?_m=downloads&_a=viewdownload&downloaditemid=1
      #       The Adyen integration manual
      #
      # @todo Parse response object and return something useful
      def capture(args = {})
        invoke_args = Adyen::SOAP.default_arguments.merge(args)
        response = invoke('payment:capture') do |message|
          message.add('payment:modificationRequest') do |req|
            req.add('payment:merchantAccount', invoke_args[:merchant_account])
            req.add('payment:modificationAmount') do |amount|
              amount.add('common:currency', invoke_args[:currency])
              amount.add('common:value', invoke_args[:value])
            end
            req.add('payment:originalReference', invoke_args[:original_reference])
          end
        end

        parse_capture(response)
      end

      # Cancel a payment.
      #
      # @param [Hash] args The paramaters to use for this call. These will be merged by any default
      #   parameters set using {Adyen::SOAP.default_arguments}. Note that every option defined below
      #   is required by the Adyen SOAP service, so please provide a value for all options.
      # @option args [String] :merchant_account The merchant account to file this payment under.
      # @option args [String] :original_reference The psp_reference of the payment to cancel.
      #
      # @return [nil] This action returns nothing of interest.
      #
      # @see https://support.adyen.com/index.php?_m=downloads&_a=viewdownload&downloaditemid=1
      #       The Adyen integration manual
      #
      # @todo Parse response object and return something useful
      def cancel(args = {})
        invoke_args = Adyen::SOAP.default_arguments.merge(args)
        response = invoke('payment:cancel') do |message|
          message.add('payment:modificationRequest') do |req|
            req.add('payment:merchantAccount', invoke_args[:merchant_account])
            req.add('payment:originalReference', invoke_args[:original_reference])
          end
        end

        parse_cancel(response)
      end

      # Refund a payment.
      #
      # @param [Hash] args The paramaters to use for this call. These will be merged by any default
      #   parameters set using {Adyen::SOAP.default_arguments}. Note that every option defined below
      #   is required by the Adyen SOAP service, so please provide a value for all options.
      # @option args [String] :merchant_account The merchant account to file this payment under.
      # @option args [String] :currency The currency code (EUR, GBP, USD, etc).
      # @option args [Integer] :value The value of the refund in cents.
      # @option args [String] :original_reference The psp_reference of the payment to refund.
      #
      # @return [nil] This action returns nothing of interest.
      #
      # @see https://support.adyen.com/index.php?_m=downloads&_a=viewdownload&downloaditemid=1
      #       The Adyen integration manual
      #
      # @todo Parse response object and return something useful
      def refund(args = {})
        invoke_args = Adyen::SOAP.default_arguments.merge(args)
        response = invoke('payment:refund') do |message|
          message.add('payment:modificationRequest') do |req|
            req.add('payment:merchantAccount', invoke_args[:merchant_account])
            req.add('payment:modificationAmount') do |amount|
              amount.add('common:currency', invoke_args[:currency])
              amount.add('common:value', invoke_args[:value])
            end
            req.add('payment:originalReference', invoke_args[:original_reference])
          end
        end

        parse_refund(response)
      end

      # Cancel or refund a payment.
      #
      # @param [Hash] args The paramaters to use for this call. These will be merged by any default
      #   parameters set using {Adyen::SOAP.default_arguments}. Note that every option defined below
      #   is required by the Adyen SOAP service, so please provide a value for all options.
      # @option args [String] :merchant_account The merchant account to file this payment under.
      # @option args [String] :original_reference The psp_reference of the payment to cancel or refund.
      #
      # @return [nil] This action returns nothing of interest.
      #
      # @see https://support.adyen.com/index.php?_m=downloads&_a=viewdownload&downloaditemid=1
      #       The Adyen integration manual
      #
      # @todo Parse response object and return something useful
      def cancel_or_refund(args = {})
        invoke_args = Adyen::SOAP.default_arguments.merge(args)
        response = invoke('payment:cancelOrRefund') do |message|
          message.add('payment:modificationRequest') do |req|
            req.add('payment:merchantAccount', invoke_args[:merchant_account])
            req.add('payment:originalReference', invoke_args[:original_reference])
          end
        end

        parse_cancel_or_refund(response)
      end

    private

      def parse_authorise(response)
        response = response.xpath('//payment:authoriseResponse/payment:paymentResult')
        {
          :psp_reference => response.xpath('./payment:pspReference/text()').to_s,
          :result_code => response.xpath('./payment:resultCode/text()').to_s,
          :auth_code => response.xpath('./payment:authCode/text()').to_s,
          :refusal_reason => response.xpath('./payment:refusalReason/text()').to_s
        }
      end

      def parse_directdebit(response)
        response = response.xpath('//payment:directdebitResponse/payment:response')
        {
          :psp_reference => response.xpath('./payment:pspReference/text()').to_s,
          :result_code => response.xpath('./payment:resultCode/text()').to_s,
          :auth_code => response.xpath('./payment:authCode/text()').to_s,
          :refusal_reason => response.xpath('./payment:refusalReason/text()').to_s
        }
      end

      def parse_capture(response)
        response = response.xpath('//payment:captureResponse/payment:captureResult')
        {
          :psp_reference => response.xpath('./payment:pspReference/text()').to_s,
          :response => response.xpath('./payment:response/text()').to_s
        }
      end

      def parse_cancel(response)
        response = response.xpath('//payment:cancelResponse/payment:cancelResult')
        {
          :psp_reference => response.xpath('./payment:pspReference/text()').to_s,
          :response => response.xpath('./payment:response/text()').to_s
        }
      end

      def parse_refund(response)
        response = response.xpath('//payment:refundResponse/payment:refundResult')
        {
          :psp_reference => response.xpath('./payment:pspReference/text()').to_s,
          :response => response.xpath('./payment:response/text()').to_s
        }
      end

      def parse_cancel_or_refund(response)
        response = response.xpath('//payment:cancelOrRefundResponse/payment:cancelOrRefundResult')
        {
          :psp_reference => response.xpath('./payment:pspReference/text()').to_s,
          :response => response.xpath('./payment:response/text()').to_s
        }
      end

    end

    # SOAP client to interact with the recurring payment service of Adyen. This clients
    # implements the following calls:
    #
    # * +listRecurring+ to list recurring contracts for a shopper, using {Adyen::SOAP::RecurringService#list}.
    # * +submitRecurring+ to submit a recurring payment for a shopper, using {Adyen::SOAP::RecurringService#submit}.
    # * +deactivateRecurring+ to cancel a recurring contract, using {Adyen::SOAP::RecurringService#deactivate}.
    #
    # Before using this service, make sure to set the SOAP username and
    # password (see {Adyen::SOAP.username} and {Adyen::SOAP.password}).
    #
    # The recurring service requires shoppers to have a recurring contract.
    # Such a contract can be set up when creating the initial payment using
    # the {Adyen::Form} methods. After the payment has been authorized, a
    # {Adyen::Notification RECURRING_CONTRACT notification} will be sent. The
    # PSP reference of this notification should be used as
    # +:recurring_reference+ parameters in these calls.
    #
    # @see https://support.adyen.com/index.php?_m=downloads&_a=viewdownload&downloaditemid=7&nav=0,3 
    #   The Adyen recurring payments manual.
    class RecurringService < Base

      # The endpoint URI for this SOAP service, in which test or live should be filled in as 
      # environment.
      # @see Adyen.environment
      ENDPOINT_URI = 'https://pal-%s.adyen.com/pal/servlet/soap/Recurring'

      # Submits a recurring payment for a recurring contract to Adyen.
      #
      # @deprecated This method has been replaced by {Adyen::SOAP::PaymentService.authorise}.
      #
      # @example 
      #   Adyen::SOAP::RecurringService.submit(
      #     :merchant_account => 'MyAccount',
      #     :shopper_reference => user.id, :shopper_email => user.email,
      #     :recurring_reference => user.contract_notification.psp_reference, 
      #     :reference => invoice.id, :currency => invoice.currency, :value => invoice.amount)
      #
      # @param [Hash] args The paramaters to use for this call. These will be merged by any default
      #   parameters set using {Adyen::SOAP.default_arguments}. Note that every option defined below
      #   is required by the Adyen SOAP service, so please provide a value for all options.
      # @option args [String] :merchant_account The merchant account to file this payment under.
      # @option args [String] :currency The currency code (EUR, GBP, USD, etc).
      # @option args [Integer] :value The value of the payment in cents.
      # @option args [Integer] :recurring_reference The psp_reference of the RECURRING_CONTRACT
      #   notification that was sent after the initial payment.
      # @option args [String] :reference Your reference for this payment. This (merchant) reference
      #   will be used in all communication to you about the status of the payment.
      #   Although it is a good idea to make sure it is unique, this is not a requirement.
      # @option args [String] :shopper_email The email address of the shopper. This does not have to
      #   match the email address supplied with the initial payment, since it may have
      #   changed in the mean time.
      # @option args [String] :shopper_reference The reference of the shopper. This should be
      #   the same as the reference that was used to create the recurring contract.
      #
      # @return [nil] This method does not return anything. The result of the payment request will
      #    be communicated with an {Adyen::Notification}.
      # @see Adyen::Notification#collect_payment_for_recurring_contract!
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

      # Retrieves the recurring contracts for a shopper.
      #
      # @param [Hash] args The paramaters to use for this call. These will be merged by any default
      #   parameters set using {Adyen::SOAP.default_arguments}. Note that every option defined below
      #   is required by the Adyen SOAP service, so please provide a value for all options.
      # @option args [String] :merchant_account The merchant account to file this payment under.
      # @option args [String] :shopper_reference The refrence of the shopper. This should be
      #   the same as the reference that was used to create the recurring contract.
      #
      # @return [Hash] This method returns a hash representation of the
      #   listRecurringDetailsResponse.
      #
      def list(args = {})
        invoke_args = Adyen::SOAP.default_arguments.merge(args)
        response = invoke('recurring:listRecurringDetails') do |message|
          message.add('recurring:request') do |req|
            req.add('recurring:recurring') do |recurring|
              recurring.add('recurring:contract', 'RECURRING')
            end
            req.add('recurring:merchantAccount', invoke_args[:merchant_account])
            req.add('recurring:shopperReference', invoke_args[:shopper_reference])
          end
        end

        parse_list_recurring_details(response)
      end

      # Disables a recurring payment contract. Requires the following arguments:
      #
      # @example
      #   Adyen::SOAP::RecurringService.disable(
      #     :merchant_account => 'MyAccount', :shopper_reference => user.id,
      #     :recurring_detail_reference => user.contract_notification.psp_reference)
      #
      # @param [Hash] args The paramaters to use for this call. These will be merged by any default
      #   parameters set using {Adyen::SOAP.default_arguments}. Note that every option defined below
      #   is required by the Adyen SOAP service, so please provide a value for all options.
      # @option args [String] :merchant_account Your merchant account.
      # @option args [String] :shopper_reference The reference to the shopper. This shopperReference
      #   must be the same as the shopperReference used in the initial payment.
      # @option args [String] :recurring_detail_reference The recurringDetailReference of the
      #   details you wish to disable. If you do not supply this field, all details for the shopper
      #   will be disabled, including the contract! This means that you can not add new details
      #   anymore.
      def disable(args = {})
        invoke_args = Adyen::SOAP.default_arguments.merge(args)
        response = invoke('recurring:disable') do |message|
          message.add('recurring:request') do |req|
            req.add('recurring:merchantAccount', invoke_args[:merchant_account])
            req.add('recurring:shopperReference', invoke_args[:shopper_reference])
            req.add('recurring:recurringDetailReference', invoke_args[:recurring_detail_reference])
          end
        end

        parse_disable(response)
      end

      # Deactivates a recurring payment contract. Requires the following arguments:
      #
      # @deprecated This method has been replaced by the {#disable} method.
      #
      # @example
      #   Adyen::SOAP::RecurringService.deactivate(
      #     :merchant_account => 'MyAccount', :shopper_reference => user.id,
      #     :recurring_reference => user.contract_notification.psp_reference, 
      #     :reference => "Terminated account #{user.account.id}")
      #
      # @param [Hash] args The paramaters to use for this call. These will be merged by any default
      #   parameters set using {Adyen::SOAP.default_arguments}. Note that every option defined below
      #   is required by the Adyen SOAP service, so please provide a value for all options.
      # @option args [String] :merchant_account The merchant account to file this payment under.
      # @option args [String] :shopper_reference The refrence of the shopper. This should be
      #   the same as the reference that was used to create the recurring contract.
      # @option args [Integer] :recurring_reference The psp_reference of the RECURRING_CONTRACT
      #   notification that was sent after the initial payment.
      # @option args [String] :reference The (merchant) reference for this contract deactivation. 
      #   Use any string you like that helps you identify this contract deactivation.
      #
      # @return [nil] This method does not return anything.
      # @see Adyen::Notification#deactivate_recurring_contract!
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

    private

      def parse_list_recurring_details(response)
        response = response.xpath('//recurring:listRecurringDetailsResponse/recurring:result')
        {
          :creation_date => response.xpath('./recurring:creationDate/text()').to_date,
          :details => response.xpath('.//recurring:RecurringDetail').map { |node| parse_recurring_detail(node) },
          :last_known_shopper_email => response.xpath('./recurring:lastKnownShopperEmail/text()').to_s,
          :shopper_reference => response.xpath('./recurring:shopperReference/text()').to_s
        }
      end

      # @todo add support for elv
      def parse_recurring_detail(node)
        result = if(not node.xpath('./recurring:card').to_s.nil?)
          parse_card(node)
        elsif(not node.xpath('./recurring:bank').to_s.nil?)
          parse_bank(node)
        end

        result.merge({
          :recurring_detail_reference => node.xpath('./recurring:recurringDetailReference/text()').to_s,
          :variant => node.xpath('./recurring:variant/text()').to_s,
          :creation_date => node.xpath('./recurring:creationDate/text()').to_date
        })
      end

      def parse_card(node)
        {
          :card => {
            :expiry_date => Date.new(node.xpath('./recurring:card/payment:expiryYear/text()').to_i, node.xpath('recurring:card/payment:expiryMonth').to_i, -1),
            :holder_name => node.xpath('./recurring:card/payment:holderName/text()').to_s,
            :number => node.xpath('./recurring:card/payment:number/text()').to_s
          }
        }
      end

      def parse_bank(node)
        {
          :bank => {
            :bank_account_number => node.xpath('./recurring:bank/payment:bankAccountNumber/text()').to_s,
            :bank_location_id => node.xpath('./recurring:bank/payment:bankLocationId/text()').to_s,
            :bank_name => node.xpath('./recurring:bank/payment:bankName/text()').to_s,
            :bic => node.xpath('./recurring:bank/payment:bic/text()').to_s,
            :country_code => node.xpath('./recurring:bank/payment:countryCode/text()').to_s,
            :iban => node.xpath('./recurring:bank/payment:iban/text()').to_s,
            :owner_name => node.xpath('./recurring:bank/payment:ownerName/text()').to_s
          }
        }
      end

      def parse_disable(response)
        response = response.xpath('//recurring:disableResponse/recurring:result')
        {
          :response => response.xpath('./recurring:response/text()').to_s
        }
      end
    end
  end
end
