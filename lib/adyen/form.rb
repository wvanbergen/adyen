require 'base64'
require 'openssl'
require 'stringio'
require 'zlib'

module Adyen
  
  LIVE_ENVIRONMENTS = ['production']
  
  module Form
    
    ACTION_URL = "https://%s.adyen.com/hpp/select.shtml"

    def autodetect_environment
      Adyen::LIVE_ENVIRONMENTS.include?(RAILS_ENV) ? 'live' : 'test'
    end

    def url(environment = nil)
      environment ||= autodetect_environment
      Adyen::Form::ACTION_URL % environment  
    end
    
    def self.hidden_fields(attributes = {})
      
    end

    module Encoding

      def self.hmac(key, message)
        digest = OpenSSL::HMAC.digest(OpenSSL::Digest::Digest.new('sha1'), hmac_key, message)
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
end