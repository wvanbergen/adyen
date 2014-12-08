require 'test_helper'

class PaymentUsing3DSecureIntegrationTest < Minitest::Test
  extend Adyen::Test::Flaky
  include Capybara::DSL

  flaky_test "3D Secure payment flow" do
    page.driver.headers = {
      "Accept" => "text/html;q=0.9,*/*",
      "User-Agent" => "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_9_2) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/36.0.1944.0 Safari/537.36" #  UUID/#{SecureRandom.uuid}
    }

    visit('/pay')

    fill_in('card[holder_name]',  :with => Adyen::TestCards::MASTERCARD_3DSECURE[:holder_name])
    fill_in('card[number]',       :with => Adyen::TestCards::MASTERCARD_3DSECURE[:number])
    fill_in('card[expiry_month]', :with => Adyen::TestCards::MASTERCARD_3DSECURE[:expiry_month])
    fill_in('card[expiry_year]',  :with => Adyen::TestCards::MASTERCARD_3DSECURE[:expiry_year])
    fill_in('card[cvc]',          :with => Adyen::TestCards::MASTERCARD_3DSECURE[:cvc])

    click_button('Pay')

    assert page.has_content?('Authenticate a transaction'), "Expected to arrive on the 3Dsecure aithentication page"
    assert_equal 'https://test.adyen.com/hpp/3d/validate.shtml', page.current_url

    fill_in('username', :with => Adyen::TestCards::MASTERCARD_3DSECURE[:username])
    fill_in('password', :with => Adyen::TestCards::MASTERCARD_3DSECURE[:password])

    click_button('Submit')

    unless page.has_content?('Payment authorized')
      if page.has_content?("You will now be redirected back")
        page.execute_script("document.getElementById('pageform').submit()")
      end
    end

    assert page.has_content?('Payment authorized'), "Expected to be returned back on our own hosted pages."
    assert_match %r{/pay/3dsecure}, page.current_url
  end
end
