require 'rubygems'

$:.unshift File.expand_path('../lib', __FILE__)
require 'adyen'
require 'adyen/api'

require 'spec/functional/initializer.rb'

payment = Adyen::API::PaymentService.new({
  :reference => '666',
  :amount => {
    :currency => 'EUR',
    :value => 2000,
  },
  #:recurring => true,
  #:card => {
    #:expiry_month => 12,
    ##:expiry_month => '',
    #:expiry_year => 2012,
    ##:expiry_year => '',
    #:holder_name => 'Adyen Test',
    ##:holder_name => '',
    #:number => '5555 5555 5555 4444',
    ##:number => '',
    #:cvc => '737',
    ##:cvc => '7',
    ## Maestro UK/Solo only
    ##:issue_number => ,
    ##:start_month => ,
    ##:start_year => ,
  #},
  :shopper => {
    #:ip => '61.294.12.12',
    :email => 'kees@example.com',
    :reference => '6',
  }
})

#puts payment.send(:authorise_payment_request_body)
#response = payment.authorise_payment
#p response
#puts response.http_response.body

#puts payment.send(:authorise_recurring_payment_request_body)
#response = payment.authorise_recurring_payment
#p response
#puts response.http_response.body

#p Adyen::API.disable_recurring_contract('6')
puts Adyen::API::RecurringService.new(:shopper => { :reference => '666' }).list.http_response.body
