require 'adyen/api/payment_service'

module Adyen
  module API
    class PaymentService < SimpleSOAPClient
      # A collection of test helpers that create and assign stubbed response instances for a
      # subsequent remote call.
      #
      # This module extends the {PaymentService} class and thus these methods are callable on it.
      module TestHelpers
        AUTHORISE_RESPONSE = SimpleSOAPClient::ENVELOPE % <<-EOXML
          <ns1:authoriseResponse xmlns:ns1="http://payment.services.adyen.com">
            <ns1:paymentResult>
              <additionalData xmlns="http://payment.services.adyen.com" xsi:nil="true"/>
              <authCode xmlns="http://payment.services.adyen.com">1234</authCode>
              <dccAmount xmlns="http://payment.services.adyen.com" xsi:nil="true"/>
              <dccSignature xmlns="http://payment.services.adyen.com" xsi:nil="true"/>
              <fraudResult xmlns="http://payment.services.adyen.com" xsi:nil="true"/>
              <issuerUrl xmlns="http://payment.services.adyen.com" xsi:nil="true"/>
              <md xmlns="http://payment.services.adyen.com" xsi:nil="true"/>
              <paRequest xmlns="http://payment.services.adyen.com" xsi:nil="true"/>
              <pspReference xmlns="http://payment.services.adyen.com">9876543210987654</pspReference>
              <refusalReason xmlns="http://payment.services.adyen.com" xsi:nil="true"/>
              <resultCode xmlns="http://payment.services.adyen.com">Authorised</resultCode>
            </ns1:paymentResult>
          </ns1:authoriseResponse>
        EOXML

        AUTHORISATION_REFUSED_RESPONSE = SimpleSOAPClient::ENVELOPE % <<-EOXML
          <ns1:authoriseResponse xmlns:ns1="http://payment.services.adyen.com">
            <ns1:paymentResult>
              <additionalData xmlns="http://payment.services.adyen.com" xsi:nil="true"/>
              <authCode xmlns="http://payment.services.adyen.com">1234</authCode>
              <dccAmount xmlns="http://payment.services.adyen.com" xsi:nil="true"/>
              <dccSignature xmlns="http://payment.services.adyen.com" xsi:nil="true"/>
              <fraudResult xmlns="http://payment.services.adyen.com" xsi:nil="true"/>
              <issuerUrl xmlns="http://payment.services.adyen.com" xsi:nil="true"/>
              <md xmlns="http://payment.services.adyen.com" xsi:nil="true"/>
              <paRequest xmlns="http://payment.services.adyen.com" xsi:nil="true"/>
              <pspReference xmlns="http://payment.services.adyen.com">9876543210987654</pspReference>
              <refusalReason xmlns="http://payment.services.adyen.com">You need to actually own money.</refusalReason>
              <resultCode xmlns="http://payment.services.adyen.com">Refused</resultCode>
            </ns1:paymentResult>
          </ns1:authoriseResponse>
        EOXML

        AUTHORISATION_REQUEST_INVALID_RESPONSE = SimpleSOAPClient::ENVELOPE % <<-EOXML
          <soap:Fault>
            <faultcode>soap:Server</faultcode>
            <faultstring>validation 101 Invalid card number</faultstring>
          </soap:Fault>
        EOXML

        # @return [AuthorisationResponse] A authorisation succeeded response instance.
        def success_stub
          http_response = Net::HTTPOK.new('1.1', '200', 'OK')
          def http_response.body; AUTHORISE_RESPONSE; end
          PaymentService::AuthorisationResponse.new(http_response)
        end

        # @return [AuthorisationResponse] An authorisation refused response instance.
        def refused_stub
          http_response = Net::HTTPOK.new('1.1', '200', 'OK')
          def http_response.body; AUTHORISATION_REFUSED_RESPONSE; end
          PaymentService::AuthorisationResponse.new(http_response)
        end

        # @return [AuthorisationResponse] An ‘invalid request’ response instance.
        def invalid_stub
          http_response = Net::HTTPOK.new('1.1', '200', 'OK')
          def http_response.body; AUTHORISATION_REQUEST_INVALID_RESPONSE; end
          PaymentService::AuthorisationResponse.new(http_response)
        end

        # Assigns a {#success_stub}, meaning the subsequent authoristaion request will be authorised.
        #
        # @return [AuthorisationResponse] A authorisation succeeded response instance.
        def stub_success!
          @stubbed_response = success_stub
        end

        # Assigns a {#refused_stub}, meaning the subsequent authoristaion request will be refused.
        #
        # @return [AuthorisationResponse] An authorisation refused response instance.
        def stub_refused!
          @stubbed_response = refused_stub
        end

        # Assigns a {#invalid_stub}, meaning the subsequent authoristaion request will be refused,
        # because the request was invalid.
        #
        # @return [AuthorisationResponse] An ‘invalid request’ response instance.
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
        DISABLE_RESPONSE = SimpleSOAPClient::ENVELOPE % <<EOS
    <ns1:disableResponse xmlns:ns1="http://recurring.services.adyen.com">
      <ns1:result>
        <response xmlns="http://recurring.services.adyen.com">
          %s
        </response>
      </ns1:result>
    </ns1:disableResponse>
EOS

        # @return [DisableResponse] A ‘disable succeeded’ response instance.
        def disabled_stub
          http_response = Net::HTTPOK.new('1.1', '200', 'OK')
          def http_response.body; DISABLE_RESPONSE % DisableResponse::DISABLED_RESPONSES.first; end
          RecurringService::DisableResponse.new(http_response)
        end

        # Assigns a {#disabled_stub}, meaning the subsequent disable request will be successful.
        def stub_disabled!
          @stubbed_response = disabled_stub
        end
      end

      extend TestHelpers
    end
  end
end
