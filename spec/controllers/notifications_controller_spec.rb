require File.expand_path('../../spec_helper', __FILE__)

describe Adyen::NotificationsController, 'when an authorised request is received' do
  before :each do
    request.env['HTTP_AUTHORIZATION'] = 'Basic ' + Base64::encode64('changeme:iamnotsecure')

    event_date = DateTime.now
    post :notify, use_route: :adyen,
                  event_code: 'AUTHORISATION',
                  psp_reference: generate(:psp_reference),
                  live: false,
                  original_reference: 'origref',
                  merchant_reference: 'booking_ref',
                  merchant_account_code: 'upmysport_test',
                  event_date: event_date
  end

  it 'will be successful' do response.response_code.should == 200 end
  it 'will return the expected content' do @response.body.should == '[accepted]' end
  it 'will create a notification' do assigns[:notification].should_not be_nil end
  it 'will create a new notification' do assigns[:notification].class.should == AdyenNotification end
end

describe Adyen::NotificationsController, 'when an unauthorised request is received' do
  before :each do
    post :notify, use_route: :adyen
  end

  it 'will not be authorised' do response.response_code.should == 401 end
end
