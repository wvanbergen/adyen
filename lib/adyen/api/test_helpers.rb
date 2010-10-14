require 'adyen/api/payment_service'

module Adyen
  module API
    class PaymentService < SimpleSOAPClient
      # A collection of test helpers that create and assign stubbed response instances for a
      # subsequent remote call.
      #
      # This module extends the {PaymentService} class and thus these methods are callable on it.
      module TestHelpers
        # @return [AuthorizationResponse] A authorisation succeeded response instance.
        def success_stub
          http_response = Net::HTTPOK.new('1.1', '200', 'OK')
          def http_response.body; AUTHORISE_RESPONSE; end
          AuthorizationResponse.new(http_response)
        end

        # @return [AuthorizationResponse] An authorisation refused response instance.
        def refused_stub
          http_response = Net::HTTPOK.new('1.1', '200', 'OK')
          def http_response.body; AUTHORISATION_REFUSED_RESPONSE; end
          AuthorizationResponse.new(http_response)
        end

        # @return [AuthorizationResponse] An ‘invalid request’ response instance.
        def invalid_stub
          http_response = Net::HTTPOK.new('1.1', '200', 'OK')
          def http_response.body; AUTHORISATION_REQUEST_INVALID_RESPONSE; end
          AuthorizationResponse.new(http_response)
        end

        # Assigns a {success_stub}, meaning the subsequent authoristaion request will be authorised.
        def stub_success!
          @stubbed_response = success_stub
        end

        # Assigns a {refused_stub}, meaning the subsequent authoristaion request will be refused.
        def stub_refused!
          @stubbed_response = refused_stub
        end

        # Assigns a {invalid_stub}, meaning the subsequent authoristaion request will be refused,
        # because the request was invalid.
        def stub_invalid!
          @stubbed_response = invalid_stub
        end
      end

      extend TestHelpers
    end

    class RecurringService < SimpleSOAPClient
      # A collection of test helpers that create and assign stubbed response instances for a
      # subsequent remote call.
      #
      # This module extends the {RecurringService} class and thus these methods are callable on it.
      module TestHelpers
        # @return [DisableResponse] A ‘disable succeeded’ response instance.
        def disabled_stub
          http_response = Net::HTTPOK.new('1.1', '200', 'OK')
          def http_response.body; DISABLE_RESPONSE % DisableResponse::DISABLED_RESPONSES.first; end
          DisableResponse.new(http_response)
        end

        # Assigns a {disabled_stub}, meaning the subsequent disable request will be successful.
        def stub_disabled!
          @stubbed_response = disabled_stub
        end
      end

      extend TestHelpers
    end
  end
end
