require File.expand_path("../../spec_helper", __FILE__)

require 'rubygems'
require 'nokogiri'

API_SPEC_INITIALIZER = File.expand_path("../initializer.rb", __FILE__)

if File.exist?(API_SPEC_INITIALIZER)

  describe Adyen::API do
    before :all do
      require API_SPEC_INITIALIZER
    end

    it "performs a payment request" do
      response = Adyen::API.authorise_payment({
        :reference => 'order-id',
        :recurring => true,
        :amount => {
          :currency => 'EUR',
          :value => '1234',
        },
        :shopper => {
          :email => 's.hopper@example.com',
          :reference => 'user-id',
          :ip => '61.294.12.12',
        },
        :card => {
          :expiry_month => 12,
          :expiry_year => 2012,
          :holder_name => 'Simon わくわく Hopper',
          :number => '4444333322221111',
          :cvc => '737',
          # Maestro UK/Solo only
          #:issue_number => ,
          #:start_month => ,
          #:start_year => ,
        }
      })
      response[:result_code].should == 'Authorised'
      response[:psp_reference].should_not be_empty
    end

    #it "performs a recurring payment request" do
      #response = Adyen::API.authorise_recurring_payment({
        #:reference => 'order-id',
        #:amount => {
          #:currency => 'EUR',
          #:value => '1234',
        #},
        #:shopper => {
          #:email => 's.hopper@example.com',
          #:reference => 'user-id',
          #:ip => '61.294.12.12',
        #}
      #})
      #response[:result_code].should == 'Authorised'
      #response[:psp_reference].should_not be_empty
    #end
  end

else
  puts "[!] To run the functional tests you'll need to create `spec/functional/initializer.rb' and configure with your test account settings. See `spec/functional/initializer.rb.sample'."
end
