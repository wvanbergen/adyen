require 'test_helper'
require 'helpers/capybara'

class PaymentWithClientSideEncryptionIntegrationTest < Minitest::Test
  extend Adyen::Test::Flaky
  include Capybara::DSL

  flaky_test "client-side encryption payment flow" do
    page.driver.headers = {
      "Accept" => "text/html;q=0.9,*/*",
      "User-Agent" => "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_9_2) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/36.0.1944.0 Safari/537.36" #  UUID/#{SecureRandom.uuid}
    }

    visit('/pay')
    fill_in('card[holder_name]',  :with => Adyen::TestCards::VISA[:holder_name])
    fill_in('card[number]',       :with => Adyen::TestCards::VISA[:number])
    fill_in('card[expiry_month]', :with => Adyen::TestCards::VISA[:expiry_month])
    fill_in('card[expiry_year]',  :with => Adyen::TestCards::VISA[:expiry_year])
    fill_in('card[cvc]',          :with => Adyen::TestCards::VISA[:cvc])

    click_button('Pay')

    assert page.has_content?('Payment authorized')
    assert_match /\A\d+\z/, find("#psp_reference").text
  end
end
