require 'test_helper'

class SignatureTest < Minitest::Test
  # HPP Signature
  def hpp_raw_params
    {
      'merchantAccount' => 'TestMerchant',
      'currencyCode' => 'EUR',
      'paymentAmount' => '199',
      'sessionValidity' => '2015-06-25T10:31:06Z',
      'shipBeforeDate' => '2015-07-01',
      'shopperLocale' => 'en_GB',
      'merchantReference' => 'SKINTEST-1435226439255',
      'skinCode' => 'X7hsNDWp',
      'sharedSecret' => hpp_shared_secret
    }
  end

  def hpp_expected_sig
    'GJ1asjR5VmkvihDJxCd8yE2DGYOKwWwJCBiV3R51NFg='
  end

  def hpp_shared_secret
    '4468D9782DEF54FCD706C9100C71EC43932B1EBC2ACF6BA0560C05AAA7550C48'
  end

  def test_hpp_sign
    signed_params = Adyen::Signature.sign(hpp_raw_params)
    assert_equal hpp_expected_sig, signed_params
  end

  def test_hpp_verify_succeeds_with_same_secret
    assert_equal true, Adyen::Signature.verify(hpp_raw_params, hpp_expected_sig)
  end

  def test_hpp_verification_fails_with_different_secret
    assert_equal false, Adyen::Signature.verify(hpp_raw_params, '1234')
  end

  # Rest Signature
  def rest_raw_params
    {
      'pspReference' => '7914073251449896',
      'originalReference' => '',
      'eventCode' => 'AUTHORISATION',
      'merchantAccountCode' => 'TestMerchant',
      'merchantReference' => 'TestPayment-1407325143704',
      'success' => 'true',
      'value' => '8650',
      'currency' => 'EUR',
      'sharedSecret' => rest_shared_secret
    }
  end

  def rest_expected_sig
    'S+5bAYKLd+L2A07Pal0pG/qBarnInaIe709YNzNcHOA='
  end

  def rest_shared_secret
    '009E9E92268087AAD241638D3325201AFC8AAE6F3DCD369B6D32E87129FFAB10'
  end

  def test_rest_sign
    signed_params = Adyen::Signature.sign(rest_raw_params, :rest)
    assert_equal rest_expected_sig, signed_params
  end

  def test_rest_verify_succeeds_with_same_secret
    assert_equal true, Adyen::Signature.verify(rest_raw_params, rest_expected_sig, :rest)
  end

  def test_rest_verification_fails_with_different_secret
    assert_equal false, Adyen::Signature.verify(rest_raw_params, '1234', :rest)
  end
end
