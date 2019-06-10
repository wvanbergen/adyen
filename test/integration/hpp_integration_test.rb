require 'test_helper'
require 'helpers/capybara'

class HPPIntegrationTest < Minitest::Test
  extend Adyen::Test::Flaky
  include Capybara::DSL

  flaky_test "HPP payment flow" do
    page.driver.headers = {
      "Accept" => "text/html;q=0.9,*/*",
      "User-Agent" => "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_9_2) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/36.0.1944.0 Safari/537.36" #  UUID/#{SecureRandom.uuid}
    }

    order_uuid = "HPP #{SecureRandom.uuid}"
    visit("/hpp?merchant_reference=#{CGI.escape(order_uuid)}")

    click_button("Pay")

    assert page.has_content?('Please select your payment method'), "Expected to arrive on Adyen's hosted payment pages."
    assert_equal 'https://test.adyen.com/hpp/select.shtml', page.current_url

    click_button('VISA')

    assert page.has_content?('Enter your Payment Details')
    assert_equal 'https://test.adyen.com/hpp/details.shtml', page.current_url

    fill_in('card.cardNumber',     :with => Adyen::TestCards::VISA[:number])
    fill_in('card.cardHolderName', :with => Adyen::TestCards::VISA[:holder_name])
    fill_in('card.cvcCode',        :with => Adyen::TestCards::VISA[:cvc])
    select(Adyen::TestCards::VISA[:expiry_month], :from => 'card.expiryMonth')
    select(Adyen::TestCards::VISA[:expiry_year],  :from => 'card.expiryYear')

    click_button('continue')

    assert page.has_content?('Please review and complete your payment')
    assert_equal 'https://test.adyen.com/hpp/completeCard.shtml', page.current_url

    click_button('pay')
    follow_redirect_back

    assert page.has_content?('Payment authorized')
    assert_match /\A\w+\z/, find("#psp_reference").text
    assert_equal order_uuid, find("#merchant_reference").text
  end

  def follow_redirect_back
    uri = URI(page.current_url.gsub('%25', '%'))
    assert_equal 'example.com', uri.host
    assert_equal '/result', uri.path
    visit('/hpp/result?' + uri.query)
  end
end
