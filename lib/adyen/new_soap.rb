module Adyen
  module SOAP
    class NewPaymentService
      REQUEST_BODY = %{<?xml version="1.0"?>
<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
  <soap:Body>
    <ns1:authorise xmlns:ns1="http://payment.services.adyen.com">
      <ns1:paymentRequest>
        <amount xmlns="http://payment.services.adyen.com">
          <currency xmlns="http://common.services.adyen.com">EUR</currency>
          <value xmlns="http://common.services.adyen.com">2000</value>
        </amount>
        <card xmlns="http://payment.services.adyen.com">
          <cvc>737</cvc>
          <expiryMonth>12</expiryMonth>
          <expiryYear>2012</expiryYear>
          <holderName>Adyen Test</holderName>
          <number>4111111111111111</number>
        </card>
        <merchantAccount xmlns="http://payment.services.adyen.com">YourMerchant</merchantAccount>
        <reference xmlns="http://payment.services.adyen.com">Your Reference Here</reference>
        <shopperEmail xmlns="http://payment.services.adyen.com">s.hopper@test.com</shopperEmail>
        <shopperIP xmlns="http://payment.services.adyen.com">61.294.12.12</shopperIP>
        <shopperReference xmlns="http://payment.services.adyen.com">Simon Hopper</shopperReference>
      </ns1:paymentRequest>
    </ns1:authorise>
  </soap:Body>
</soap:Envelope>}

      attr_reader :params

      def initialize(params = {})
        @params = params
      end

      def authorise_payment_request_body
        REQUEST_BODY
      end
    end
  end
end
