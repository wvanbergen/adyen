module Adyen
  module HPP
    # The Signature module can sign and verify HMAC SHA-256 signatures for Hosted Payment Pages
    module Signature
      extend self

      # Sign the parameters with the given shared secret
      # @param [Hash] params The set of parameters to sign.
      # @param [String] shared_secret The shared secret for signing.
      # @return [Hash] params The params that were passed in plus a new `merchantSig` param
      def sign(params, shared_secret)
        params = params.dup
        params.delete('merchantSig')
        params["sharedSecret"] ||= shared_secret
        params.merge('merchantSig' => Adyen::Signature.sign(params))
      end

      # Verify the parameters with the given shared secret
      # @param [Hash] params The set of parameters to verify. Must include a `merchantSig`
      #   param that will be compared to the signature we calculate.
      # @param [String] shared_secret The shared secret for verification.
      # @return [Boolean] true if the `merchantSig` in the params matches our calculated signature
      def verify(params, shared_secret)
        params = params.dup
        params["sharedSecret"] ||= shared_secret
        their_sig = params.delete('merchantSig')
        raise ArgumentError, "params must include 'merchantSig' for verification" if their_sig.empty?
        Adyen::Signature.verify(params, their_sig)
      end
    end
  end
end
