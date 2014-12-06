require 'date'
require 'openssl'
require 'base64'

module Adyen
  module Util
    extend self

    # Returns a valid Adyen string representation for a date
    def format_date(date)
      case date
      when Date, DateTime, Time
        date.strftime('%Y-%m-%d')
      when String
        raise ArgumentError, "Invalid date notation: #{date.inspect}!" unless /^\d{4}-\d{2}-\d{2}$/ =~ date
        date
      else
        raise ArgumentError, "Cannot convert #{date.inspect} to date!"
      end
    end

    # Returns a valid Adyen string representation for a timestamp
    def format_timestamp(time)
      case time
      when Date, DateTime, Time
        time.strftime('%Y-%m-%dT%H:%M:%SZ')
      when String
        raise ArgumentError, "Invalid timestamp notation: #{time.inspect}!" unless /^\d{4}-\d{2}-\d{2}T\d{2}\:\d{2}\:\d{2}Z$/ =~ time
        time
      else
        raise ArgumentError, "Cannot convert #{time.inspect} to timestamp!"
      end
    end

    # Returns a base64-encoded signature for a message
    # @param [String] hmac_key The secret key to use for the HMAC signature.
    # @param [String] message The message to sign.
    # @return [String] The signature, base64-encoded.
    def hmac_base64(hmac_key, message)
      digest = OpenSSL::HMAC.digest(OpenSSL::Digest.new('sha1'), hmac_key, message)
      Base64.strict_encode64(digest).strip
    end

    # Retuns a message gzip-compressed and base64-encoded.
    # @param [String] message The message to compress and encode.
    # @return [String] The compressed and encoded version of the message
    def gzip_base64(message)
      sio = StringIO.new
      gz  = Zlib::GzipWriter.new(sio)
      gz.write(message)
      gz.close
      Base64.strict_encode64(sio.string)
    end

    # Returns the camelized version of a string.
    # @param [:to_s] identifier The identifier to turn to camelcase.
    # @return [String] The camelcase version of the identifier provided.
    def camelize(identifier)
      CAMELCASE_EXCEPTIONS[identifier.to_s] || identifier.to_s.gsub(/_+(.)/) { $1.upcase }
    end

    # Returns the underscore version of a string.
    # @param [:to_s] identifier The identifier to turn to underscore notation.
    # @return [String] The underscore version of the identifier provided.
    def underscore(identifier)
      UNDERSCORE_EXCEPTIONS[identifier.to_s] || identifier.to_s
        .gsub(/([A-Z]{2,})([A-Z])/) { "#{$1.downcase}#{$2}" }
        .gsub(/(?!\A)([A-Z][a-z]*)/, '_\1')
        .downcase
    end

    # Transforms the nested parameters Hash into a 'flat' Hash which is understood by adyen. This is:
    #  * all keys are camelized
    #  * all keys are stringified
    #  * nested hash is flattened, keys are prefixed with root key
    #
    # @example
    #    flatten {:billing_address => { :street => 'My Street'}}
    #
    #    # resolves in:
    #    {'billingAddress.street' =>  'My Street'}
    #
    # @param [Hash] nested_hash The nested hash to transform
    # @param [String] prefix The prefix to add to the key
    # @param [Hash] return_hash The new hash which is retruned (needed for recursive calls)
    # @return [Hash] The return hash filled with camelized and prefixed key, stringified value
    def flatten(nested_hash, prefix = "", return_hash = {})
      nested_hash ||= {}
      nested_hash.inject(return_hash) do |hash, (key, value)|
        key = "#{prefix}#{camelize(key)}"
        if value.is_a?(Hash)
          flatten(value, "#{key}.", return_hash)
        else
          hash[key] = value.to_s
        end
        hash
      end
    end

    # Transforms a flat hash into a nested hash structure.
    #  * all keys are underscored
    #  * all keys are stringified
    #  * flattened hash is deflattened, using . as namespace separator
    #
    # @example
    #    deflatten {'billingAddress.street' =>  'My Street'}
    #
    #    # resolves in:
    #    {'billing_address' => { 'street' => 'My Street'}}
    #
    # @param [Hash] flattened_hash The flat hash to transform
    # @param [Hash] return_hash The new hash which will be returned (needed for recursive calls)
    # @return [Hash] A nested hash structure, using strings as key.
    def deflatten(flattened_hash, return_hash = {})
      return return_hash if flattened_hash.nil?
      flattened_hash.each do |key, value|
        deflatten_pair(key, value, return_hash)
      end
      return_hash
    end

    private

    def deflatten_pair(key, value, return_hash)
      head, rest = key.split('.', 2)
      key = underscore(head)
      if rest.nil?
        raise ArgumentError, "Duplicate key in flattened hash." if return_hash.key?(key)
        return_hash[key] = value
      else
        return_hash[key] ||= {}
        raise ArgumentError, "Key nesting conflict in flattened hash." unless return_hash[key].is_a?(Hash)
        deflatten_pair(rest, value, return_hash[key])
      end
    end

    # This hash contains exceptions to the standard underscore to camelcase conversion rules.
    CAMELCASE_EXCEPTIONS = {
      'shopper_ip' => 'shopperIP'
    }

    # This hash contains exceptions to the standard camelcase to underscore conversion rules.
    UNDERSCORE_EXCEPTIONS = CAMELCASE_EXCEPTIONS.invert

    private_constant :CAMELCASE_EXCEPTIONS, :UNDERSCORE_EXCEPTIONS
  end
end
