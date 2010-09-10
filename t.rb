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

payment = Adyen::SOAP::NewPaymentService.new({
  :merchant_account => 'FngtpsCOM',
  :reference => 'orderID',
  :amount => {
    :currency => 'EUR',
    :value => 2000,
  },
  :card => {
    :expiry_month => 12,
    :expiry_year => 2012,
    :holder_name => 'Adyen Test',
    :number => '4444333322221111',
    :cvc => '737',
    # Maestro UK/Solo only
    #:issue_number => ,
    #:start_month => ,
    #:start_year => ,
  },
  :shopper => {
    :ip => '61.294.12.12',
    :email => 's.hopper@test.com',
    :reference => 'userID',
  },
  # TODO: figure out if the value has any significance
  #:fraud_offset => 1,
})

p payment
p payment.authorise_payment
