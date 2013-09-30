FactoryGirl.define do
  sequence :psp_reference do |n|
    "psp_ref_#{n}"
  end

  factory :adyen_notification do
    live                   false
    merchant_account_code  'mac'
    event_code             'AUTHORISATION'
    event_date             Time.now
    processed              false
    psp_reference
    currency               'EUR'
  end
end
