require 'adyen/hpp/signature'
require 'adyen/hpp/client'
require 'adyen/hpp/request'
require 'adyen/hpp/response'

module Adyen
  module HPP
    # The DOMAIN of the Adyen payment system that still requires the current
    # Adyen enviroment.
    HPP_DOMAIN = "%s.adyen.com"

    # The URL of the Adyen payment system that still requires the current
    # domain and payment flow to be filled.
    HPP_URL = "https://%s/hpp/%s.shtml"

    class Error < Adyen::Error
    end

    class ForgedResponse < Adyen::HPP::Error
    end

    class Notification
      def initialize(request)
      end
    end
  end
end
