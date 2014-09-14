require 'adyen/rest/client'

module Adyen
  module REST
    CA_FILE = File.expand_path('../api/cacert.pem', __FILE__)

    def self.client(configuration = Adyen.configuration)
      Adyen::REST::Client.new(configuration)
    end

    Error = Class.new(StandardError)
    Unauthorized = Class.new(Error)
  end
end
