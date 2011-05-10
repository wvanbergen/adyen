require 'adyen'
require 'adyen/api/simple_soap_client'
require 'adyen/api/payment_service'
require 'adyen/api/recurring_service'

module Adyen
  # The API module contains classes that interact with the Adyen SOAP API.
  #
  # You'll need to provide a username and password to interact with Adyen:
  #
  #     Adyen.configuration.api_username = 'ws@Company.MyAccount'
  #     Adyen.configuration.api_password = 'secret'
  #
  # Furthermore, you can setup default parameters, which will be used by every API call, by using
  # {Adyen::API.default_arguments}.
  #
  # The following classes, which handle the SOAP services, are available:
  #
  # * {PaymentService}   - for authorisation of, and modification to, payments.
  # * {RecurringService} - for handling recurring contract details.
  #
  # *However*, direct use of these classes is discouraged in favor of the shortcut methods defined
  # on the API module. These methods *expect* that you set the :merchant_account as a default
  # parameter.
  #
  # Note that you'll need an Adyen notification PSP reference for some of the calls. Because of
  # this, store all notifications that Adyen sends to you. Moreover, the responses to these calls 
  # do *not* tell you whether or not the requested action was successful. For this you will also 
  # have to check the notification.
  #
  # = Authorising payments
  #
  # To authorise payments, not recurring ones, the customers payment details will have to pass
  # through your application’s infrastucture. Because of this you will have to contact Adyen and
  # provide the necessary paperwork which says that you’re PCI DSS compliant, before you are given
  # access to Adyen’s API.
  #
  # Unless you are going to process over twenty thousand payments anually, the PCI DSS
  # Self-Assessment Questionnaire (SAQ) type A will _probably_ suffice.
  #
  # @see http://en.wikipedia.org/wiki/Payment_Card_Industry_Data_Security_Standard
  # @see https://www.pcisecuritystandards.org/saq/instructions_dss.shtml
  # @see http://usa.visa.com/merchants/risk_management/cisp_merchants.html
  module API
    extend self

    # Authorise a payment.
    #
    # @see capture_payment
    #
    # Of all options, only the details are optional. But since the IP is’s used in various risk
    # checks, and the email and reference are needed to enable recurring contract, it’s a good
    # idea to supply it anyway.
    #
    # @example
    #   response = Adyen::API.authorise_payment(
    #     invoice.id,
    #     { :currency => 'EUR', :value => invoice.amount },
    #     { :reference => user.id, :email => user.email, :ip => '8.8.8.8' },
    #     { :holder_name => "Simon Hopper", :number => '4444333322221111', :cvc => '737', :expiry_month => 12, :expiry_year => 2012 }
    #   )
    #   response.authorised? # => true
    #
    # @param          [Numeric,String] reference      Your reference (ID) for this payment.
    # @param          [Hash]           amount         A hash describing the money to charge.
    # @param          [Hash]           shopper        A hash describing the shopper.
    # @param          [Hash]           card           A hash describing the creditcard details.
    #
    # @option amount  [String]         :currency      The ISO currency code (EUR, GBP, USD, etc).
    # @option amount  [Integer]        :value         The value of the payment in discrete cents,
    #                                                 unless the currency does not have cents.
    #
    # @option shopper [Numeric,String] :reference     The shopper’s reference (ID).
    # @option shopper [String]         :email         The shopper’s email address.
    # @option shopper [String]         :ip            The shopper’s IP address.
    #
    # @option card    [String]         :holder_name   The full name on the card.
    # @option card    [String]         :number        The card number.
    # @option card    [String]         :cvc           The card’s verification code.
    # @option card    [Numeric,String] :expiry_month  The month in which the card expires.
    # @option card    [Numeric,String] :expiry_year   The year in which the card expires.
    #
    # @param [Boolean] enable_recurring_contract      Store the payment details at Adyen for
    #                                                 future recurring or one-click payments.
    #
    # @return [PaymentService::AuthorisationResponse] The response object which holds the
    #                                                 authorisation status.
    def authorise_payment(reference, amount, shopper, card, enable_recurring_contract = false)
      PaymentService.new(
        :reference => reference,
        :amount    => amount,
        :shopper   => shopper,
        :card      => card,
        :recurring => enable_recurring_contract
      ).authorise_payment
    end

    # Authorise a recurring payment. The contract detail will default to the ‘+latest+’, which
    # is generally what you’d want.
    #
    # @see capture_payment
    #
    # Of all options, only the shopper’s IP address is optional. But since it’s used in various
    # risk checks, it’s a good idea to supply it anyway.
    #
    # @example
    #   response = Adyen::API.authorise_recurring_payment(
    #     invoice.id,
    #     { :currency => 'EUR', :value => invoice.amount },
    #     { :reference => user.id, :email => user.email, :ip => '8.8.8.8' }
    #   )
    #   response.authorised? # => true
    #
    # @param          [Numeric,String] reference      Your reference (ID) for this payment.
    # @param          [Hash]           amount         A hash describing the money to charge.
    # @param          [Hash]           shopper        A hash describing the shopper.
    #
    # @option amount  [String]         :currency      The ISO currency code (EUR, GBP, USD, etc).
    # @option amount  [Integer]        :value         The value of the payment in discrete cents,
    #                                                 unless the currency does not have cents.
    #
    # @option shopper [Numeric,String] :reference     The shopper’s reference (ID).
    # @option shopper [String]         :email         The shopper’s email address.
    # @option shopper [String]         :ip            The shopper’s IP address.
    #
    # @param [String] recurring_detail_reference      The recurring contract reference to use.
    # @see list_recurring_details
    #
    # @return [PaymentService::AuthorisationResponse] The response object which holds the
    #                                                 authorisation status.
    def authorise_recurring_payment(reference, amount, shopper, recurring_detail_reference = 'LATEST')
      PaymentService.new(
        :reference => reference,
        :amount    => amount,
        :shopper   => shopper,
        :recurring_detail_reference => recurring_detail_reference
      ).authorise_recurring_payment
    end

    # Authorise a ‘one-click’ payment. A specific contract detail *has* to be specified.
    #
    # @see capture_payment
    #
    # Of all options, only the shopper’s IP address is optional. But since it’s used in various
    # risk checks, it’s a good idea to supply it anyway.
    #
    # @example
    #   detail  = Adyen::API.list_recurring_details(user.id).details.last[:recurring_detail_reference]
    #   payment = Adyen::API.authorise_one_click_payment(
    #     invoice.id,
    #     { :currency => 'EUR', :value => invoice.amount },
    #     { :reference => user.id, :email => user.email, :ip => '8.8.8.8' },
    #     '737',
    #     detail
    #   )
    #   payment.authorised? # => true
    #
    # @param          [Numeric,String] reference      Your reference (ID) for this payment.
    # @param          [Hash]           amount         A hash describing the money to charge.
    # @param          [Hash]           shopper        A hash describing the shopper.
    # @param          [String]         card_cvc       The card’s verification code.
    #
    # @option amount  [String]         :currency      The ISO currency code (EUR, GBP, USD, etc).
    # @option amount  [Integer]        :value         The value of the payment in discrete cents,
    #                                                 unless the currency does not have cents.
    #
    # @option shopper [Numeric,String] :reference     The shopper’s reference (ID).
    # @option shopper [String]         :email         The shopper’s email address.
    # @option shopper [String]         :ip            The shopper’s IP address.
    #
    # @param [String] recurring_detail_reference      The recurring contract reference to use.
    # @see list_recurring_details
    #
    # @return [PaymentService::AuthorisationResponse] The response object which holds the
    #                                                 authorisation status.
    def authorise_one_click_payment(reference, amount, shopper, card_cvc, recurring_detail_reference)
      PaymentService.new(
        :reference => reference,
        :amount    => amount,
        :shopper   => shopper,
        :card      => { :cvc => card_cvc },
        :recurring_detail_reference => recurring_detail_reference
      ).authorise_one_click_payment
    end

    # Capture an authorised payment.
    #
    # You can also configure your merchant account to automatically capture authorised payments
    # in the merchant account settings.
    #
    # @see https://ca-test.adyen.com/ca/ca/accounts/manageMerchantAccount.shtml
    #
    # Note that the response of this request will only indicate whether or
    # not the request has been successfuly received. Check the notitification
    # for the actual mutation status.
    #
    # @param         [String]         psp_reference   The PSP reference, from Adyen, of the
    #                                                 previously authorised request.
    # @param         [Hash]           amount          A hash describing the money to charge.
    # @option amount [String]         :currency       The ISO currency code (EUR, GBP, USD, etc).
    # @option amount [Integer]        :value          The value of the payment in discrete cents,
    #                                                 unless the currency does not have cents.
    #
    # @return [PaymentService::CaptureResponse] The response object.
    def capture_payment(psp_reference, amount)
      PaymentService.new(:psp_reference => psp_reference, :amount => amount).capture
    end

    # Refund a captured payment.
    #
    # Note that the response of this request will only indicate whether or
    # not the request has been successfuly received. Check the notitification
    # for the actual mutation status.
    #
    # @param         [String]         psp_reference   The PSP reference, from Adyen, of the
    #                                                 previously authorised request.
    # @param         [Hash]           amount          A hash describing the money to charge.
    # @option amount [String]         :currency       The ISO currency code (EUR, GBP, USD, etc).
    # @option amount [Integer]        :value          The value of the payment in discrete cents,
    #                                                 unless the currency does not have cents.
    #
    # @return [PaymentService::RefundResponse] The response object.
    def refund_payment(psp_reference, amount)
      PaymentService.new(:psp_reference => psp_reference, :amount => amount).refund
    end

    # Cancel or refund a payment. Use this if you want to cancel or refund
    # the payment, but are unsure what the current status is.
    #
    # Note that the response of this request will only indicate whether or
    # not the request has been successfuly received. Check the notitification
    # for the actual mutation status.
    #
    # @param         [String]         psp_reference   The PSP reference, from Adyen, of the
    #                                                 previously authorised request.
    #
    # @return [PaymentService::CancelOrRefundResponse] The response object.
    def cancel_or_refund_payment(psp_reference)
      PaymentService.new(:psp_reference => psp_reference).cancel_or_refund
    end

    # Cancel an authorised payment.
    #
    # Note that the response of this request will only indicate whether or
    # not the request has been successfuly received. Check the notitification
    # for the actual mutation status.
    #
    # @param         [String]         psp_reference   The PSP reference, from Adyen, of the
    #                                                 previously authorised request.
    #
    # @return [PaymentService::CancelResponse] The response object.
    def cancel_payment(psp_reference)
      PaymentService.new(:psp_reference => psp_reference).cancel
    end

    # Retrieve the recurring contract details for a shopper.
    #
    # @param         [String]       shopper_reference The ID used to store payment details for
    #                                                 this shopper.
    #
    # @return [RecurringService::ListResponse] The response object.
    def list_recurring_details(shopper_reference)
      RecurringService.new(:shopper => { :reference => shopper_reference }).list
    end

    # Disable the recurring contract details for a shopper.
    #
    # @param         [String]       shopper_reference The ID used to store payment details for
    #                                                 this shopper.
    # @param [String,nil] recurring_detail_reference  The ID of a specific recurring contract.
    #                                                 Defaults to all.
    #
    # @return [RecurringService::DisableResponse] The response object.
    def disable_recurring_contract(shopper_reference, recurring_detail_reference = nil)
      RecurringService.new({
        :shopper => { :reference => shopper_reference },
        :recurring_detail_reference => recurring_detail_reference
      }).disable
    end

    # Stores the recurring token for a shopper.
    #
    # # @example
    #   response = Adyen::API.store_recurring_token(
    #     invoice.id,
    #     { :reference => user.id, :email => user.email, :ip => '8.8.8.8' },
    #     { :holder_name => "Simon Hopper", :number => '4444333322221111', :cvc => '737', :expiry_month => 12, :expiry_year => 2012 }
    #   )
    #   response.success? # => true
    #   # Now we can authorize this credit card.
    #   authorize_response = Adyen::API.authorise_recurring_payment(
    #     invoice.id,
    #     { :currency => 'EUR', :value => invoice.amount },
    #     { :reference => user.id, :email => user.email, :ip => '8.8.8.8' },
    #     response.recurring_detail_reference
    #   )
    #   authorize_response.authorised? # => true
    #
    # @param          [Numeric,String] reference      Your reference (ID) for this payment.
    # @param          [Hash]           shopper        A hash describing the shopper.
    # @param          [Hash]           card           A hash describing the creditcard details.
    #
    # @option shopper [Numeric,String] :reference     The shopper’s reference (ID).
    # @option shopper [String]         :email         The shopper’s email address.
    # @option shopper [String]         :ip            The shopper’s IP address.
    #
    # @option card    [String]         :holder_name   The full name on the card.
    # @option card    [String]         :number        The card number.
    # @option card    [String]         :cvc           The card’s verification code.
    # @option card    [Numeric,String] :expiry_month  The month in which the card expires.
    # @option card    [Numeric,String] :expiry_year   The year in which the card expires.
    #
    # @return [RecurringService::StoreTokenResponse] The response object
    def store_recurring_token(reference, shopper, card)
      RecurringService.new({
        :reference => reference,
        :shopper   => shopper,
        :card      => card
      }).store_token
    end
  end
end
