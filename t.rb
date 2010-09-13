$:.unshift File.expand_path('../lib', __FILE__)

require 'rubygems'
require 'adyen'
require 'adyen/soap'
require 'adyen/new_soap'

Handsoap::Service.logger = $stdout

Adyen::SOAP.username = 'ws@Company.Fngtps'
Adyen::SOAP.password = 'aT"gn!e;l35g'

#p Adyen.autodetect_environment

#Adyen::SOAP::PaymentService.authorise({
  #:merchant_account => 'FngtpsCOM',
  #:currency => 'EUR', :value => 2000,
  #:reference => 'orderID',
  #:card => {
    #:expiry_month => 12,
    #:expiry_year => 2012,
    #:holder_name => 'Adyen Test',
    #:number => '4444333322221111',
    #:cvc => '737',
    ## Maestro UK/Solo only
    ##:issue_number => ,
    ##:start_month => ,
    ##:start_year => ,
  #},
  #:shopper_ip => '61.294.12.12',
  #:shopper_email => 's.hopper@test.com',
  #:shopper_reference => 'userID',
  ## TODO: figure out if the value has any significance
  ##:fraud_offset => 1,
#})

#class Adyen::SOAP::NewPaymentService
  #def authorise_payment_request_body
    #%{<?xml version="1.0"?> <soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
#<soap:Body> <ns1:storeToken xmlns:ns1="http://recurring.services.adyen.com">
#<ns1:request> <bank xmlns="http://recurring.services.adyen.com" xsi:nil="true"/> <card xmlns="http://recurring.services.adyen.com">
#<expiryMonth xmlns="http://payment.services.adyen.com">12</expiryMonth> <expiryYear xmlns="http://payment.services.adyen.com">2012</expiryYear> <holderName xmlns="http://payment.services.adyen.com">Adyen Test</holderName> <number xmlns="http://payment.services.adyen.com">4111111111111111</number>
#</card> <elv xmlns="http://recurring.services.adyen.com" xsi:nil="true"/> <merchantAccount xmlns="http://recurring.services.adyen.com">
#FngtpsCOM
#</merchantAccount> <recurring xmlns="http://recurring.services.adyen.com">
#<contract xmlns="http://payment.services.adyen.com">RECURRING</contract>
#<recurringDetailName xmlns="http://payment.services.adyen.com" xsi:nil="true"/> </recurring> <shopperEmail xmlns="http://recurring.services.adyen.com">email@shopper.com</shopperEmail> <shopperReference xmlns="http://recurring.services.adyen.com">
#TheShopperReference
#</shopperReference> </ns1:request>
#</ns1:storeToken> </soap:Body>
#</soap:Envelope>
    #}
  #end
#end

payment = Adyen::SOAP::NewPaymentService.new({
  :merchant_account => 'FngtpsCOM',
  :reference => '5678',
  :amount => {
    :currency => 'EUR',
    :value => 2000,
  },
  :recurring => true,
  :card => {
    :expiry_month => 12,
    :expiry_year => 2012,
    :holder_name => 'Adyen Test',
    :number => '5555 5555 5555 4444',
    :cvc => '737',
    # Maestro UK/Solo only
    #:issue_number => ,
    #:start_month => ,
    #:start_year => ,
  },
  :shopper => {
    :ip => '61.294.12.12',
    :email => 's.hopper@test.com',
    :reference => '12',
  },
  # TODO: figure out if the value has any significance
  #:fraud_offset => 1,
})

puts payment.authorise_payment_request_body
response = payment.authorise_payment
p response
puts response.body

#require 'adyen/soap'
#p Adyen::SOAP::RecurringService.list(:merchant_account => 'FngtpsCOM', :shopper_reference => '12')
