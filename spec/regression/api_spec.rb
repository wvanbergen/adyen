require File.expand_path("../../spec_helper", __FILE__)
require 'tempfile'

Spec::Matchers.define :equal_regression_fixture do |fixture_name|
  match do |actual|
    equal = false
    regression_file = File.expand_path("../api/#{fixture_name}.xml", __FILE__)
    Tempfile.open("adyen-api-regression-#{fixture_name}") do |actual_file|
      actual_file << actual; actual_file.flush
      unless equal = File.read(actual_file.path) == File.read(regression_file)
        @diff = `diff -U 1 '#{regression_file}' '#{actual_file.path}'`
      end
    end
    equal
  end

  failure_message_for_should { @diff }
end

###############################################################################
#
# These regression files are copied from the manuals. They are only modified to
# * have the same order as the generated XML
# * use the same namespace prefixes consistently
#

describe Adyen::API, "concerning regression examples from the manuals" do
  it "creates a correct `authorise payment' request body" do
    @payment = Adyen::API::PaymentService.new({
      :merchant_account => 'YourMerchant',
      :reference => 'Your Reference Here',
      :amount => { :currency => 'EUR', :value => 2000 },
      :card => {
        :holder_name => 'Adyen Test',
        :number => '4111111111111111',
        :cvc => '737',
        :expiry_month => '12',
        :expiry_year => '2012'
      },
      :shopper => {
        :reference => 'Simon Hopper',
        :email => 's.hopper@test.com',
        :ip => '61.294.12.12'
      }
    })
    body = @payment.send(:authorise_payment_request_body)
    body.should equal_regression_fixture(:authorise_payment)
  end

  it "creates a correct `authorise recurring payment' request body" do
    @payment = Adyen::API::PaymentService.new({
      :merchant_account => 'YourMerchantAccount',
      :reference => 'RecurringPayment-0001',
      :amount => { :currency => 'EUR', :value => 100 },
      :shopper => {
        :reference => 'TheShopperReference',
        :email => 'email@shopper.com',
        :ip => '1.1.1.1'
      }
    })
    body = @payment.send(:authorise_recurring_payment_request_body)
    body.should equal_regression_fixture(:authorise_recurring_payment)
  end
end
