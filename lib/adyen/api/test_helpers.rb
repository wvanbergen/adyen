require 'adyen/api/payment_service'

module Adyen
  module API
    class PaymentService < SimpleSOAPClient
      class << self
        def success_stub
          http_response = Net::HTTPOK.new('1.1', '200', 'OK')
          def http_response.body; AUTHORISE_RESPONSE; end
          AuthorizationResponse.new(http_response)
        end

        def refused_stub
          http_response = Net::HTTPOK.new('1.1', '200', 'OK')
          def http_response.body; AUTHORISATION_REFUSED_RESPONSE; end
          AuthorizationResponse.new(http_response)
        end

        def invalid_stub
          http_response = Net::HTTPOK.new('1.1', '200', 'OK')
          def http_response.body; AUTHORISATION_REQUEST_INVALID_RESPONSE; end
          AuthorizationResponse.new(http_response)
        end

        def stub_success!
          @stubbed_response = success_stub
        end

        def stub_refused!
          @stubbed_response = refused_stub
        end

        def stub_invalid!
          @stubbed_response = invalid_stub
        end
      end
    end

    class RecurringService < SimpleSOAPClient
      class << self
        def disabled_stub
          http_response = Net::HTTPOK.new('1.1', '200', 'OK')
          def http_response.body; DISABLE_RESPONSE % DisableResponse::DISABLED_RESPONSES.first; end
          DisableResponse.new(http_response)
        end

        def stub_disabled!
          @stubbed_response = disabled_stub
        end
      end
    end
  end
end
