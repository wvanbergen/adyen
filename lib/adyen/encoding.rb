require 'base64'
require 'openssl'
require 'stringio'
require 'zlib'

module Adyen
  module Encoding
    def self.hmac_base64(hmac_key, message)
      digest = OpenSSL::HMAC.digest(OpenSSL::Digest.new('sha1'), hmac_key, message)
      Base64.encode64(digest).strip
    end

    def self.gzip_base64(message)
      sio = StringIO.new
      gz  = Zlib::GzipWriter.new(sio)
      gz.write(message)
      gz.close
      Base64.encode64(sio.string).gsub("\n", "")
    end
  end
end