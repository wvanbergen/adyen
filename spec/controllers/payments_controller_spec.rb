require File.expand_path('../../spec_helper', __FILE__)

describe Adyen::PaymentsController, 'when a result is returned' do
  it 'should respond with 200 success' do
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