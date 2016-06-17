require 'openssl'
require 'base64'

module Adyen
  # The Signature module generic to sign and verify HMAC SHA-256 signatures
  module Signature
    extend self

    # Sign the parameters with the given shared secret
    # @param [Hash] params The set of parameters to verify. Must include a `shared_secret` param for signing/verification
    #
    # @param [String] type The type to sign (:hpp or :rest). Default is :hpp
    # @return [String] The signature
    def sign(params, type = :hpp)
      shared_secret = params.delete('sharedSecret')
      raise ArgumentError, "Cannot sign parameters without a shared secret" unless shared_secret
      sig = OpenSSL::HMAC.digest(OpenSSL::Digest.new('sha256'), Array(shared_secret).pack("H*"), string_to_sign(params, type))
      Base64.encode64(sig).strip
    end

    # Compare a signature calculated with anoter HMAC Signature
    # @param [Hash] params The set of parameters to verify. Must include a `shared_secret`
    #   param for signing/verification
    # @param [String] hmacSignature will be compared to the signature calculated.
    # @return [Boolean] true if the `hmacSignature` matches our calculated signature
    def verify(params, hmacSignature, type = :hpp)
      raise ArgumentError,"hmacSignature cannot be empty for verification" if hmacSignature.empty?
      our_sig = sign(params, type)
      secure_compare(hmacSignature, our_sig)
    end

    private

    def string_to_sign(params, type)
      string = ''
      if type == :hpp
        string = sorted_keys(params) + sorted_values(params)
      elsif type == :rest
        keys = %w(pspReference originalReference merchantAccountCode merchantReference value currency eventCode success)
        string = sorted_values(params, keys)
      else
        raise NotImplementedError, 'Type sign not implemented'
      end

      string.map{ |el| escape_value(el) }.join(':')
    end

    def sorted_keys(hash, keys_to_sort = nil)
      hash.sort.map{ |el| el[0] }
    end

    def sorted_values(hash, keys_to_sort = nil)
      if keys_to_sort.is_a? Array
        keys_to_sort.map { |key| hash[key] }
      else
        hash.sort.map{ |el| el[1] }
      end
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
