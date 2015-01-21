require 'adyen/hpp/signature'

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

    class Client
      attr_reader :environment, :skin_code

      def initialize(environment, skin_code, shared_secret, default_attribues = {})
        @environment, @skin_code, @shared_secret = environment, skin_code, shared_secret
      end
    end

    class Request
      def initialize(skin)
      end
    end

    class Response
      def initialize(request)
      end
    end

    class Notification
      def initialize(request)
      end
    end
  end
end
