require 'test_helper'
require 'adyen/hpp/signature'

class HPPSignatureTest < Minitest::Test
  def setup
    # values from https://docs.adyen.com/pages/viewpage.action?pageId=5376964
    @shared_secret = "4468D9782DEF54FCD706C9100C71EC43932B1EBC2ACF6BA0560C05AAA7550C48"

    @expected_sig = 'GJ1asjR5VmkvihDJxCd8yE2DGYOKwWwJCBiV3R51NFg='

    @raw_params = {
      'merchantAccount' => 'TestMerchant',
      'currencyCode' => 'EUR',
      'paymentAmount' => '199',
      'sessionValidity' => '2015-06-25T10:31:06Z',
      'shipBeforeDate' => '2015-07-01',
      'shopperLocale' => 'en_GB',
      'merchantReference' => 'SKINTEST-1435226439255',
      'skinCode' => 'X7hsNDWp',
    }
  end

  def test_sign
    signed_params = Adyen::HPP::Signature.sign(@raw_params, @shared_secret)
    assert_equal @expected_sig, signed_params['merchantSig']
  end

  def test_verify_succeeds_with_same_secret
    signed_params = @raw_params.merge('merchantSig' => @expected_sig)
    assert_equal true, Adyen::HPP::Signature.verify(signed_params, @shared_secret)
  end

  def test_verification_fails_with_different_secret
    signed_params = @raw_params.merge('merchantSig' => @expected_sig)
    assert_equal false, Adyen::HPP::Signature.verify(signed_params, '12345')
  end
end
