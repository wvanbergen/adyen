require 'base64'
require 'openssl'
require 'stringio'
require 'zlib'

module Adyen
  LIVE_RAILS_ENVIRONMENTS = ['production']  

  def self.autodetect_environment
    (defined?(RAILS_ENV) && Adyen::LIVE_RAILS_ENVIRONMENTS.include?(RAILS_ENV)) ? 'live' : 'test'
  end
  
  # Returns a valid string representation for a date to use in Adyen communications
  def self.date(date)
    case date
    when Date, DateTime, Time
      date.strftime('%Y-%m-%d')
    else
      raise "Invalid date notation: #{date.inspect}!" unless /^\d{4}-\d{2}-\d{2}$/ =~ date
      date
    end
  end
  
  # Returns a valid string representation for a timestamp to use in Adyen communications
  def self.time(time)
    case time
    when Date, DateTime, Time
      time.strftime('%Y-%m-%dT%H:%M:%SZ')
    else
      raise "Invalid timestamp notation: #{time.inspect}!" unless /^\d{4}-\d{2}-\d{2}T\d{2}\:\d{2}\:\d{2}Z$/ =~ time
      time
    end
  end
  
  module Price
    def self.in_cents(price)
      ((price * 100).round).to_i.to_s
    end

    def self.from_cents(price)
      BigDecimal.new(price.to_s) / 100
    end
  end

  module Encoding

    def self.hmac_base64(hmac_key, message)
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

require 'adyen/form'
require 'adyen/soap'
