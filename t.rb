require 'rubygems'

$:.unshift File.expand_path('../lib', __FILE__)
require 'adyen'
require 'adyen/api'

Adyen::API.default_params[:merchant_account] = 'FngtpsCOM'
Adyen::API.username = 'ws@Company.Fngtps'
Adyen::API.password = 'aT"gn!e;l35g'

payment = Adyen::API::PaymentService.new({
  #:reference => '666',
  :amount => {
    :currency => 'EUR',
    :value => 2000,
  },
  :recurring => true,
  :card => {
    :expiry_month => 12,
    #:expiry_month => '',
    :expiry_year => 2012,
    #:expiry_year => '',
    :holder_name => 'Adyen Test',
    #:holder_name => '',
    :number => '5555 5555 5555 4444',
    #:number => '',
    :cvc => '737',
    #:cvc => '7',
    # Maestro UK/Solo only
    #:issue_number => ,
    #:start_month => ,
    #:start_year => ,
  },
  :shopper => {
    :ip => '61.294.12.12',
    :email => 's.hopper@test.com',
    :reference => '12',
  }
})

puts payment.send(:authorise_payment_request_body)
response = payment.authorise_payment
p response
puts response.http_response.body

#require 'adyen/soap'
#p Adyen::SOAP::RecurringService.list(:merchant_account => 'FngtpsCOM', :shopper_reference => '12')
