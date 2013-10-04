require File.expand_path('../../spec_helper', __FILE__)

describe Adyen::PaymentsController, 'when a valid result is received' do
  it 'should respond with 200 success' do
    Adyen::Signature.stub(:redirect_signature_check).and_return(true)
    params = {authResult:'',
              pspReference: '',
              merchantReference: '',
              skinCode: '',
              merchantSig: '',
              paymentMethod: '',
              shopperLocale:'',
              merchantReturnData:''}

    get :result, params.merge(use_route: :adyen)

    expect(response.response_code).to eq(200)
  end
end

describe Adyen::PaymentsController, 'when an invalid signature is received' do
  it 'will raise an error' do
    Adyen::Signature.stub(:redirect_signature_check).and_return(false)
    params = {authResult:'',
              pspReference: '',
              merchantReference: '',
              skinCode: '',
              merchantSig: '',
              paymentMethod: '',
              shopperLocale:'',
              merchantReturnData:''}

    expect { get :result, params.merge(use_route: :adyen) }.to raise_error Adyen::InvalidSignature
  end
end