require 'adyen/base'
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
  # on the API module. These methods *require* that you set the :merchant_account *beforehand* as
  # a default parameter passed in all API calls:
  #
  #     Adyen.configuration.default_api_params[:merchant_account] = 'MerchantAccount'
  #
  # For Rails apps, you can also set it `application.rb` config block, like this:
  #
  #     config.adyen.default_api_params = { :merchant_account => 'MerchantAccount' }
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

    # Generate a Billet - *Brazillian users only*
    #
    # Billet (Boleto Bancário), often simply referred to as Boleto, is an
    # offline payment method used in Brazil . The consumer will take the Boleto form to
    # an ATM, bank, an approved facility, or access their online banking system
    # to complete the payment. Once the Boleto is paid, the bank will send Adyen
    # a file confirming that the payment was made, this usually takes one day, but
    # it may occur up to 6 days after the payment. If a Boleto is not paid, the
    # transaction will expire once the expirationDate is reached. For more
    # information check the Adyen API Manual - 7 - Boleto Bancário(page 30)
    #
    # @example
    #   response = Adyen::API.generate_billet(
    #     invoice.id
    #     { currency: "BRL", value: (invoice.amount).to_i },
    #     { first_name: "Simon", last_name: "Hopper" },
    #     document_number,
    #     selected_brand,
    #     "2016-10-29T23:00:00.000Z",
    #     "Please send payment email to payment@example.com after payment."
    #   )
    #   response.success? # => true
    #
    #
    # @param          [Numeric,String] reference          Your reference (ID) for this payment.
    # @param          [Hash]           amount             A hash describing the money to charge.
    # @param          [Hash]           shopper_name       A hash describing the shopper.
    # @param          [String]         document_number    Social Security number (CPF in Brazil)
    # @param          [String]         selected_brand     Billet brand
    # @param          [String]         delivery_date      Payment date limit in ISO8601 format
    # @param optional [String]         shopper_statement  Payment instructions to Shopper
    #
    # @option amount  [String]         :currency      The ISO currency code (EUR, GBP, USD, etc).
    # @option amount  [Integer]        :value         The value of the payment in discrete cents,
    #                                                 unless the currency does not have cents.
    #
    # @option shopper_name [String]    :first_name    The shopper’s first name
    # @option shopper_name [String]    :last_name     The shopper’s last name
    #
    #
    # @return [PaymentService::BilletResponse] The response object which holds the billet url.
    #
    def generate_billet(reference, amount, shopper_name, social_security_number, selected_brand, delivery_date, shopper_statement = nil)
      params = { :reference              => reference,
                 :amount                 => amount,
                 :shopper_name           => shopper_name,
                 :social_security_number => social_security_number,
                 :selected_brand         => selected_brand,
                 :delivery_date          => delivery_date,
                 :shopper_statement      => shopper_statement }
      PaymentService.new(params).generate_billet
    end

    # Make an instant payment.
    #
    # Technically - authorisation with immediate (no delay) capture.
    # @see authorise_payment
    def pay_instantly(reference, amount, shopper, card, enable_recurring_contract = false, fraud_offset = nil)
      authorise_payment(reference, amount, shopper, card, enable_recurring_contract, fraud_offset, true)
    end

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
    #     { :reference => user.id, :email => user.email, :ip => '8.8.8.8', :statement => 'invoice number 123456'},
    #     { :holder_name => "Simon Hopper", :number => '4444333322221111', :cvc => '737',
    #       :expiry_month => 12, :expiry_year => 2012 }
    #   )
    #   response.authorised? # => true
    #
    # @param          [Numeric,String] reference      Your reference (ID) for this payment.
    # @param          [Hash]           amount         A hash describing the money to charge.
    # @param          [Hash]           shopper        A hash describing the shopper.
    # @param          [Hash]           card           A hash describing the credit card details.
    #
    # @option amount  [String]         :currency      The ISO currency code (EUR, GBP, USD, etc).
    # @option amount  [Integer]        :value         The value of the payment in discrete cents,
    #                                                 unless the currency does not have cents.
    #
    # @option shopper [Numeric,String] :reference     The shopper’s reference (ID).
    # @option shopper [String]         :email         The shopper’s email address.
    # @option shopper [String]         :ip            The shopper’s IP address.
    # @option shopper [String]         :statement     The shopper's statement
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
    # @param [Numeric] fraud_offset                   Modify Adyen's fraud check by supplying
    #                                                 an offset for their calculation.
    #
    # @return [PaymentService::AuthorisationResponse] The response object which holds the
    #                                                 authorisation status.
    def authorise_payment(reference, amount, shopper, card, enable_recurring_contract = false, fraud_offset = nil, instant_capture = false)
      params = { :reference    => reference,
                 :amount       => amount,
                 :shopper      => shopper,
                 :card         => card,
                 :recurring    => enable_recurring_contract,
                 :fraud_offset => fraud_offset,
                 :instant_capture => instant_capture }
      PaymentService.new(params).authorise_payment
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
    #     { :reference => user.id, :email => user.email, :ip => '8.8.8.8', :statement => 'invoice number 123456' }
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
    # @option shopper [String]         :statement     The shopper's statement
    #
    # @param [String] recurring_detail_reference      The recurring contract reference to use.
    # @see list_recurring_details
    #
    # @param [Numeric] fraud_offset                   Modify Adyen's fraud check by supplying
    #                                                 an offset for their calculation.
    #
    # @return [PaymentService::AuthorisationResponse] The response object which holds the
    #                                                 authorisation status.
    def authorise_recurring_payment(reference, amount, shopper, recurring_detail_reference = 'LATEST', fraud_offset = nil, instant_capture = false)
      params = { :reference => reference,
                 :amount    => amount,
                 :shopper   => shopper,
                 :recurring_detail_reference => recurring_detail_reference,
                 :fraud_offset => fraud_offset,
                 :instant_capture => instant_capture }
      PaymentService.new(params).authorise_recurring_payment
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
    #     { :reference => user.id, :email => user.email, :ip => '8.8.8.8', :statement => 'invoice number 123456' },
    #     { :cvc => '737' }
    #     detail
    #   )
    #   payment.authorised? # => true
    #
    # @param          [Numeric,String] reference      Your reference (ID) for this payment.
    # @param          [Hash]           amount         A hash describing the money to charge.
    # @param          [Hash]           shopper        A hash describing the shopper.
    # @param          [Hash]           card           A hash describing the credit card details.
    #
    # @option amount  [String]         :currency      The ISO currency code (EUR, GBP, USD, etc).
    # @option amount  [Integer]        :value         The value of the payment in discrete cents,
    #                                                 unless the currency does not have cents.
    #
    # @option shopper [Numeric,String] :reference     The shopper’s reference (ID).
    # @option shopper [String]         :email         The shopper’s email address.
    # @option shopper [String]         :ip            The shopper’s IP address.
    # @option shopper [String]         :statement     The shopper's statement
    #
    # @option card    [String]         :cvc           The card’s verification code.
    #
    # @param [String] recurring_detail_reference      The recurring contract reference to use.
    # @see list_recurring_details
    #
    # @param [Numeric] fraud_offset                   Modify Adyen's fraud check by supplying
    #                                                 an offset for their calculation.
    #
    # @return [PaymentService::AuthorisationResponse] The response object which holds the
    #                                                 authorisation status.
    def authorise_one_click_payment(reference, amount, shopper, card, recurring_detail_reference, fraud_offset = nil, instant_capture = false)
      params = { :reference => reference,
                 :amount    => amount,
                 :shopper   => shopper,
                 :card      => card,
                 :recurring_detail_reference => recurring_detail_reference,
                 :fraud_offset => fraud_offset,
                 :instant_capture => instant_capture }
      PaymentService.new(params).authorise_one_click_payment
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

    # Stores and tokenises the payment details so that recurring payments can be made in the
    # future. It can be either a credit card or ELV (Elektronisches Lastschriftverfahren).
    #
    #  For instance, this is how you would store credit card details:
    #
    # # @example
    #   response = Adyen::API.store_recurring_token(
    #     { :reference => user.id, :email => user.email, :ip => '8.8.8.8', :statement => 'invoice number 123456' },
    #     { :holder_name => "Simon Hopper", :number => '4444333322221111',
    #       :expiry_month => 12, :expiry_year => 2012 }
    #   )
    #
    # Or use the following to store ELV details:
    #
    # # @example
    #   response = Adyen::API.store_recurring_token(
    #     { :reference => user.id, :email => user.email, :ip => '8.8.8.8', :statement => 'invoice number 123456' },
    #     { :bank_location => "Berlin", :bank_name => "TestBank", :bank_location_id => "12345678",
    #       :holder_name => "Simon Hopper", :number => "1234567890" }
    #   )
    #   response.stored? # => true
    #
    #   # Now we can authorize a payment with the token.
    #   authorize_response = Adyen::API.authorise_recurring_payment(
    #     invoice.id,
    #     { :currency => 'EUR', :value => invoice.amount },
    #     { :reference => user.id, :email => user.email, :ip => '8.8.8.8', :statement => 'invoice number 123456' },
    #     response.recurring_detail_reference
    #   )
    #   authorize_response.authorised? # => true
    #
    # @param            [Hash]           params                A hash describing the credit card or
    #                                                          ELV details.
    #
    # @option shopper   [Numeric,String] :reference            The shopper’s reference (ID).
    # @option shopper   [String]         :email                The shopper’s email address.
    # @option shopper   [String]         :ip                   The shopper’s IP address.
    # @option shopper   [String]         :statement            The shopper's statement
    #
    # @option params    [String]         :holder_name          The full name on the card or of the
    #                                                          account holder.
    # @option params    [String]         :number               The card or account number.
    #
    # ##### Credit card specific options:
    #
    # @option params    [Numeric,String] :expiry_month         The month in which the card expires.
    # @option params    [Numeric,String] :expiry_year          The year in which the card expires.
    #
    # ##### ELV specific options:
    #
    # @option params    [String]         :bank_location        The Bank Location.
    # @option params    [String]         :bank_name            The Bank Name.
    # @option params    [Numeric,String] :bank_location_id     The Bank Location ID (Bankleitzahl).
    #
    # @return [RecurringService::StoreTokenResponse] The response object
    def store_recurring_token(shopper, params)
        payment_method = params.include?(:bank_location_id) ? :elv : :card
        RecurringService.new({
          :shopper => shopper,
          payment_method => params
        }).store_token
    end
  end
end
