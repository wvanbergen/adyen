require File.expand_path('../../spec_helper', __FILE__)

module PaymentsController
  module SpecHelper
    def create_params(overrides={})
      {'authResult' => 'AUTHORISED',
       'pspReference' => '',
       'merchantReference' => 'trans1',
       'skinCode' => 'skin_secret',
       'merchantSig' => '',
       'paymentMethod' => '',
       'shopperLocale' => '',
       'merchantReturnData' => ''}.merge overrides
    end
  end
end

describe Adyen::PaymentsController, 'when a valid result is received' do
  include PaymentsController::SpecHelper

  before :each do
    Adyen.setup do |config|
    end
    params = create_params

    Adyen::PaymentResult.any_instance.stub(:has_valid_signature?).and_return(true)
    get :result, params.merge(use_route: :adyen)
  end

  it 'will be a successful authorisation' do
    expect(controller.payment_success?).to be_true
  end

  it 'will give the correct merchant reference' do
    expect(controller.merchant_reference).to eq('trans1')
  end

  it 'should respond with 200 success' do
    expect(response).to redirect_to('/adyen/payments/complete')
  end
end

describe Adyen::PaymentsController, 'when a redirect location has been configured' do
  include PaymentsController::SpecHelper

  before :each do
    Adyen.setup do |config|
      config.redirect_payment_with do |c|
        "/some/other/path?ref=#{c.merchant_reference}"
      end
    end

    Adyen::PaymentResult.any_instance.stub(:has_valid_signature?).and_return(true)

    get :result, create_params('authResult' => 'AUTHORISED', 'merchantReference' => 'transaction_1', use_route: :adyen)
  end

  it 'will redirect to the configured location' do
    expect(response).to redirect_to('/some/other/path?ref=transaction_1')
  end

  it 'will be a successful authorisation' do
    expect(controller.payment_success?).to be_true
  end
end

describe Adyen::PaymentsController, 'when an invalid signature is received' do
  include PaymentsController::SpecHelper

  it 'will raise an error' do
    Adyen::PaymentResult.any_instance.stub(:has_valid_signature?).and_return(false)
    expect { get :result, create_params(use_route: :adyen) }.to raise_error Adyen::InvalidSignature
  end
end

describe Adyen::PaymentsController, 'when showing payment complete' do
  include PaymentsController::SpecHelper

  it 'will be successful' do
    get :complete, use_route: :adyen
    expect(response).to be_success
  end
end
