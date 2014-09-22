require 'adyen'
require 'adyen/rest/client'

module Adyen
  module REST
    def self.client(options = {})
      Adyen::REST::Client.new(
        Adyen.configuration.environment, 
        Adyen.configuration.api_username, 
        Adyen.configuration.api_password,
        options
      )
    end
  end
end
