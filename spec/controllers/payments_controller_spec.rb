require File.expand_path('../../spec_helper', __FILE__)

module PaymentsController
  module TestHelper
    def create_params overrides
      {authResult: '',
       pspReference: '',
       merchantReference: '',
       skinCode: '',
       merchantSig: '',
       paymentMethod: '',
       shopperLocale:'',
       merchantReturnData:''}.merge overrides
    end
  end
end

describe Adyen::PaymentsController, 'when a valid result is received' do
  include PaymentsController::TestHelper

  it 'should respond with 200 success' do
    Adyen.setup {}
    Adyen::Signature.stub(:redirect_signature_check).and_return(true)

    get :result, create_params(use_route: :adyen)

    expect(response).to redirect_to('/adyen/payments/complete')
  end
end

describe Adyen::PaymentsController, 'when a redirect location has been configured' do
  include PaymentsController::TestHelper

  before :each do
    @results = {}

    Adyen.setup do |config|
      config.payment_result_redirect = lambda do |c|
        ref = c.params[:merchantReference]
        @results[:success] = c.payment_success?
        "/some/other/path?ref=#{ref}"
      end
    end

    Adyen::Signature.stub(:redirect_signature_check).and_return(true)

    get :result, create_params(authResult: 'AUTHORISATION', merchantReference: 'transaction_1', use_route: :adyen)
  end

  it 'will redirect to the configured location' do
    expect(response).to redirect_to('/some/other/path?ref=transaction_1')
  end

  it 'will have a successful payment' do
    expect(@results[:success]).to be_true
  end
end

describe Adyen::PaymentsController, 'when an invalid signature is received' do
  include PaymentsController::TestHelper

  it 'will raise an error' do
    Adyen::Signature.stub(:redirect_signature_check).and_return(false)

    expect { get :result, create_params(use_route: :adyen) }.to raise_error Adyen::InvalidSignature
  end
end

describe Adyen::PaymentsController, 'when showing payment complete' do
  include PaymentsController::TestHelper

  it 'will be successful' do
    get :complete, use_route: :adyen
    expect(response).to be_success
  end
end
