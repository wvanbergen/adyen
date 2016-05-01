require 'test_helper'

class SignatureTest < Minitest::Test
  def setup
    # values from https://docs.adyen.com/pages/viewpage.action?pageId=5376964

    @expected_sig = 'S+5bAYKLd+L2A07Pal0pG/qBarnInaIe709YNzNcHOA='

    @raw_params = {
      'hmacSignature' => @expected_sig,
      'pspReference' => '7914073251449896',
      'originalReference' => '',
      'eventCode' => 'AUTHORISATION',
      'merchantAccountCode' => 'TestMerchant',
      'merchantReference' => 'TestPayment-1407325143704',
      'success' => 'true',
      'value' => '8650',
      'currency' => 'EUR',
      'sharedSecret' => '009E9E92268087AAD241638D3325201AFC8AAE6F3DCD369B6D32E87129FFAB10'
    }
  end

  def test_sign
    assert_equal @expected_sig, Adyen::REST::Signature.sign(@raw_params)
  end

  def test_verify_succeeds_with_same_secret
    assert_equal true, Adyen::REST::Signature.verify(@raw_params)
  end

  def test_verification_fails_with_different_secret
    params = @raw_params.merge('hmacSignature' => '123')
    assert_equal false, Adyen::REST::Signature.verify(params)
  end
end
