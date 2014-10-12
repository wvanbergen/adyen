require 'test_helper'
require 'capybara/poltergeist'

class SimplePaymentsIntegrationTest < Minitest::Test
  include Capybara::DSL

  def setup
    Capybara.app = Adyen::TestServer
    Capybara.default_driver = :poltergeist
  end  

  def teardown
    Capybara.reset_sessions!
    Capybara.use_default_driver
  end

  def test_authorisation_and_capture
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

    assert_equal 200, page.status_code
    assert page.has_content?('Payment authorized')
    psp_reference = find("#psp_reference").text

    visit("/capture/#{psp_reference}")
    fill_in('value', with: '1234')
    click_button('Capture')

    assert_equal 200, page.status_code
    assert page.has_content?('Capture received')
  end

  def test_authorisation_and_cancel
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

    assert_equal 200, page.status_code
    assert page.has_content?('Payment authorized')
    psp_reference = find("#psp_reference").text

    visit("/cancel/#{psp_reference}")
    click_button('Cancel')

    assert_equal 200, page.status_code
    assert page.has_content?('Capture received')
  end
end