module Adyen
  module REST
    # The Signature module can sign and verify HMAC SHA-256 signatures for API
    module Signature
      extend self

      # Sign the parameters with the given shared secret
      # @param [Hash] params The set of parameters to sign. Should sent `sharedSecret` to sign.
      # @return [String] signature from parameters
      def sign(params)
        Adyen::Signature.sign(params, :rest)
      end

      # Verify the parameters with the given shared secret
      # @param [Hash] params The set of parameters to verify.
      # Should include `sharedSecret` param to sign and the `hmacSignature` param to compare with the signature calculated
      # @return [Boolean] true if the `hmacSignature` in the params matches our calculated signature
      def verify(params)
        their_sig = params.delete('hmacSignature')
        raise ArgumentError, "params must include 'hmacSignature' for verification" if their_sig.empty?
        Adyen::Signature.verify(params, their_sig, :rest)
      end
    end
  end
end
