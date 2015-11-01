require 'openssl'
require 'base64'

module Adyen
  module HPP
    # The Signature module can sign and verify HMAC SHA-256 signatures for Hosted Payment Pages
    module Signature
      extend self

      # Sign the parameters with the given shared secret
      # @param [Hash] params The set of parameters to sign
      # @param [String] shared_secret The shared secret for signing/verification. Can also be sent in the
      #   params hash with the `sharedSecret` key.
      # @return [Hash] params The params that were passed in plus a new `merchantSig` param
      def sign(params, shared_secret = nil)
        params = params.dup
        param_shared_secret = params.delete('sharedSecret')
        shared_secret ||= param_shared_secret
        params.delete('merchantSig')
        raise ArgumentError, "Cannot verify a signature without a shared secret" unless shared_secret
        sig = OpenSSL::HMAC.digest(OpenSSL::Digest.new('sha256'), Array(shared_secret).pack("H*"), string_to_sign(params))
        params.merge('merchantSig' => Base64.encode64(sig).strip)
      end

      # Verify the parameters with the given shared secret
      # @param [Hash] params The set of parameters to verify. Must include a `merchantSig`
      #   param that will be compared to the signature we calculate.
      # @param [String] shared_secret The shared secret for signing/verification. Can also be sent in the
      #   params hash with the `sharedSecret` key.
      # @return [Boolean] true if the `merchantSig` in the params matches our calculated signature
      def verify(params, shared_secret = nil)
        params = params.dup
        param_shared_secret = params.delete('sharedSecret')
        shared_secret ||= param_shared_secret
        their_sig = params.delete('merchantSig')
        raise ArgumentError, "params must include 'merchantSig' for verification" if their_sig.empty?
        our_sig = sign(params, shared_secret)['merchantSig']
        secure_compare(their_sig, our_sig)
      end

      private

      def string_to_sign(params)
        (sorted_keys(params) + sorted_values(params)).map{ |el| escape_value(el) }.join(':')
      end

      def sorted_keys(hash)
        hash.sort.map{ |el| el[0] }
      end

      def sorted_values(hash)
        hash.sort.map{ |el| el[1] }
      end

      def escape_value(value)
        value.gsub(':', '\\:').gsub('\\', '\\\\')
      end

      # Constant-time compare for two fixed-length strings
      # Stolen from https://github.com/rails/rails/commit/c8c660002f4b0e9606de96325f20b95248b6ff2d
      def secure_compare(a, b)
        return false unless a.bytesize == b.bytesize

        l = a.unpack "C#{a.bytesize}"

        res = 0
        b.each_byte { |byte| res |= byte ^ l.shift }
        res == 0
      end
    end
  end
end
