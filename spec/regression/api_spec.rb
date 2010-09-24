require File.expand_path("../../spec_helper", __FILE__)
require 'tempfile'

module APISpecHelper
  def self.xmllint_format(file)
    `xmllint --format --nsclean '#{file}'`
  end
end

Spec::Matchers.define :equal_regression_fixture do |fixture_name|
  match do |actual|
    regression_file = File.expand_path("../api/#{fixture_name}.xml", __FILE__)
    Tempfile.open("adyen-api-regression-#{fixture_name}") do |actual_file|
      actual_file << actual; actual_file.flush
      formatted = APISpecHelper.xmllint_format(actual_file.path)
      actual_file.rewind; actual_file << formatted; actual_file.flush
      puts File.read(actual_file.path)

      if File.read(actual_file.path) == File.read(regression_file)
        true
      else
        @diff = `diff '#{regression_file}' '#{actual_file.path}'`
        false
      end
    end
  end

  failure_message_for_should do |actual|
    "expected that #{actual} would be a precise multiple of #{expected}"
    "diff:\n#{@diff}"
  end
end

describe Adyen::API, "concerning regression examples from the manuals" do
  it "creates an equal `authorise recurring payment' request body" do
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
