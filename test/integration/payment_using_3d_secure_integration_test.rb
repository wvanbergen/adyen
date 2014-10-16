require 'test_helper'
require 'capybara/poltergeist'

class PaymentUsing3DSecureIntegrationTest < Minitest::Test
  include Capybara::DSL

  def setup
    Capybara.app = Adyen::ExampleServer
    Capybara.default_driver = :poltergeist
    Capybara.default_wait_time = 5
  end

  def teardown
    Capybara.reset_sessions!
    Capybara.use_default_driver
  end

  def test_3d_secure_flow
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

    puts page.html
    click_button('Continue')

    puts page.html

    assert_equal 'https://test.adyen.com/hpp/3d/validate.shtml', page.current_url

    fill_in('username', :with => Adyen::TestCards::MASTERCARD_3DSECURE[:username])
    fill_in('password', :with => Adyen::TestCards::MASTERCARD_3DSECURE[:password])

    assert_equal 'https://test.adyen.com/hpp/3d/validate.shtml', page.current_url

    click_button('Submit')

    assert_match %r{/pay/3dsecure}, page.current_url
  end
end
