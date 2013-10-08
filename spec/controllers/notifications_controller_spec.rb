require File.expand_path('../../spec_helper', __FILE__)

describe Adyen::NotificationsController, 'when an authorised request is received' do
  before :each do
    Adyen.setup do |config|
      config.http_username = 'changeme'
      config.http_password = 'iamnotsecure'
    end

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

describe Adyen::NotificationsController, 'when the wrong credentials are provided' do
  before :each do
    Adyen.setup do |config|
      config.http_username = 'changeme'
      config.http_password = 'iamnotsecure'
    end

    request.env['HTTP_AUTHORIZATION'] = 'Basic ' + Base64::encode64('notcorrect:iamnotsecure')

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

  it 'will not be authorised' do response.response_code.should == 401 end
end

describe Adyen::NotificationsController, 'when basic auth is disabled' do
  before :each do
    Adyen.setup do |config|
      config.disable_basic_auth = true
    end

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
end

describe Adyen::NotificationsController, 'when no config block is provided to the engine' do
  it 'will raise the expected error' do expect { Adyen.setup }.to raise_error Adyen::ConfigMissing end
end

describe Adyen::NotificationsController, 'when no config has been run' do
  before :each do
    Adyen.instance_variable_set(:@config, nil)
  end

  it 'will raise the expected error' do
    event_date = DateTime.now
    expect {
      post :notify, use_route: :adyen,
         event_code: 'AUTHORISATION',
         psp_reference: generate(:psp_reference),
         live: false,
         original_reference: 'origref',
         merchant_reference: 'booking_ref',
         merchant_account_code: 'upmysport_test',
         event_date: event_date
    }.to raise_error Adyen::NotConfigured
  end
end

describe Adyen::NotificationsController, 'when the request is invalid' do
  before :each do
    Adyen.setup do |config|
      config.disable_basic_auth = true
    end

    post :notify, use_route: :adyen,
         event_code: 'AUTHORISATION',
         live: false,
         psp_reference: generate(:psp_reference),
         merchant_reference: 'booking_ref'
  end

  it 'will be successful' do response.response_code.should == 200 end
  it 'will return the expected content' do @response.body.should == '[accepted]' end
end

describe Adyen::NotificationsController, 'when the request throws a record invalid error' do
  before :each do
    Adyen.setup do |config|
      config.disable_basic_auth = true
    end

    event_date = DateTime.now
    post :notify, use_route: :adyen,
         event_code: 'AUTHORISATION',
         live: false,
         original_reference: 'origref',
         merchant_reference: 'booking_ref',
         merchant_account_code: 'upmysport_test',
         event_date: event_date
  end

  it 'will be successful' do response.response_code.should == 200 end
  it 'will return the expected content' do @response.body.should == '[accepted]' end
end

describe Adyen::NotificationsController, 'when an unauthorised request is received' do
  before :each do
    Adyen.setup do |config|
      config.disable_basic_auth = false
    end

    post :notify, use_route: :adyen
  end

  it 'will not be authorised' do response.response_code.should == 401 end
end
