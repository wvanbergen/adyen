require 'spec_helper'

shared_examples 'a valid signature' do
  let(:expected_signature) {'ytt3QxWoEhAskUzUne0P5VA9lPw='}

  let(:params) {{ 'authResult' => 'AUTHORISED', 'pspReference' => '1211992213193029',
                  'merchantReference' => 'Internet Order 12345', 'skinCode' => '4aD37dJA',
                  'merchantSig' => expected_signature }}

  let(:signature) {Adyen::PaymentResult.new(params)}

  context '#redirect_signature_match' do
    it 'will pass' do
      expect(signature.has_valid_signature?(secret)).to be_true
    end
  end

  context '#redirect_signature' do
    it 'will be correct' do
      expect(signature.signature(secret)).to eq(expected_signature)
    end
  end

  context '#redirect_signature_string' do
    it 'will return the correct signature string' do
      expect(signature.signature_string).to eq('AUTHORISED1211992213193029Internet Order 123454aD37dJA')
    end
  end

  context '.redirect_signature_check' do
    it 'will pass' do
      expect(Adyen::Signature.redirect_signature_check(params, secret)).to be_true
    end
  end
end

describe 'using an explicit secret' do
  let(:secret) {'Kah942*$7sdp0)'}

  it_behaves_like 'a valid signature'
end

describe 'using a secret configured in the engine' do
  before :all do
    Adyen.setup do |config|
      config.add_main_skin '4aD37dJA', 'Kah942*$7sdp0)'
    end
  end

  let(:secret){nil}

  it_behaves_like 'a valid signature'
end

describe 'using a secret configured directly' do
  before :all do
    Adyen.configuration.register_form_skin(:main, '4aD37dJA', 'Kah942*$7sdp0)')
  end

  let(:secret){nil}

  it_behaves_like 'a valid signature'
end

describe 'adding additional parameters' do
  let(:expected_signature) {'ytt3QxWoEhAskUzUne0P5VA9lPw='}

  let(:params) {{ 'authResult' => 'AUTHORISED', 'pspReference' => '1211992213193029',
                  'merchantReference' => 'Internet Order 12345', 'skinCode' => '4aD37dJA',
                  'merchantSig' => expected_signature, 'merchantReturnData' => 'testing1234' }}

  let(:signature) {Adyen::PaymentResult.new(params)}

  context '#redirect_signature_string' do
    it 'will calculate the correct value' do
      expect(signature.signature_string).to eq 'AUTHORISED1211992213193029Internet Order 123454aD37dJAtesting1234'
    end
  end
end