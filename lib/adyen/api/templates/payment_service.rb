module Adyen
  module API
    class PaymentService < SimpleSOAPClient
      LAYOUT = <<EOS
    <payment:authorise xmlns:payment="http://payment.services.adyen.com" xmlns:recurring="http://recurring.services.adyen.com" xmlns:common="http://common.services.adyen.com">
      <payment:paymentRequest>
        <payment:merchantAccount>%s</payment:merchantAccount>
        <payment:reference>%s</payment:reference>
%s
      </payment:paymentRequest>
    </payment:authorise>
EOS

      CAPTURE_LAYOUT = <<EOS
    <payment:capture xmlns:payment="http://payment.services.adyen.com" xmlns:recurring="http://recurring.services.adyen.com" xmlns:common="http://common.services.adyen.com">
      <payment:modificationRequest>
        <payment:merchantAccount>%s</payment:merchantAccount>
        <payment:originalReference>%s</payment:originalReference>
        <payment:modificationAmount>
          <common:currency>%s</common:currency>
          <common:value>%s</common:value>
        </payment:modificationAmount>
      </payment:modificationRequest>
    </payment:capture>
EOS

      REFUND_LAYOUT = <<EOS
    <payment:refund xmlns:payment="http://payment.services.adyen.com" xmlns:recurring="http://recurring.services.adyen.com" xmlns:common="http://common.services.adyen.com">
      <payment:modificationRequest>
        <payment:merchantAccount>%s</payment:merchantAccount>
        <payment:originalReference>%s</payment:originalReference>
        <payment:modificationAmount>
          <common:currency>%s</common:currency>
          <common:value>%s</common:value>
        </payment:modificationAmount>
      </payment:modificationRequest>
    </payment:refund>
EOS

      CANCEL_OR_REFUND_LAYOUT = <<EOS
    <payment:cancelOrRefund xmlns:payment="http://payment.services.adyen.com" xmlns:recurring="http://recurring.services.adyen.com" xmlns:common="http://common.services.adyen.com">
      <payment:modificationRequest>
        <payment:merchantAccount>%s</payment:merchantAccount>
        <payment:originalReference>%s</payment:originalReference>
      </payment:modificationRequest>
    </payment:cancelOrRefund>
EOS

      CANCEL_LAYOUT = <<EOS
    <payment:cancel xmlns:payment="http://payment.services.adyen.com" xmlns:recurring="http://recurring.services.adyen.com" xmlns:common="http://common.services.adyen.com">
      <payment:modificationRequest>
        <payment:merchantAccount>%s</payment:merchantAccount>
        <payment:originalReference>%s</payment:originalReference>
      </payment:modificationRequest>
    </payment:cancel>
EOS

      AMOUNT_PARTIAL = <<EOS
        <payment:amount>
          <common:currency>%s</common:currency>
          <common:value>%s</common:value>
        </payment:amount>
EOS

      CARD_CVC_ONLY_PARTIAL = <<EOS
        <payment:card>
          <payment:cvc>%s</payment:cvc>
        </payment:card>
EOS

      CARD_PARTIAL = <<EOS
        <payment:card>
          <payment:holderName>%s</payment:holderName>
          <payment:number>%s</payment:number>
          <payment:cvc>%s</payment:cvc>
          <payment:expiryYear>%s</payment:expiryYear>
          <payment:expiryMonth>%02d</payment:expiryMonth>
        </payment:card>
EOS

      RECURRING_PARTIAL = <<EOS
        <payment:recurring>
          <payment:contract>RECURRING,ONECLICK</payment:contract>
        </payment:recurring>
EOS

      RECURRING_PAYMENT_BODY_PARTIAL = <<EOS
        <payment:recurring>
          <payment:contract>%s</payment:contract>
        </payment:recurring>
        <payment:selectedRecurringDetailReference>%s</payment:selectedRecurringDetailReference>
        <payment:shopperInteraction>ContAuth</payment:shopperInteraction>
        %s
EOS

      SHOPPER_PARTIALS = {
        :reference => '        <payment:shopperReference>%s</payment:shopperReference>',
        :email     => '        <payment:shopperEmail>%s</payment:shopperEmail>',
        :ip        => '        <payment:shopperIP>%s</payment:shopperIP>',
      }

      # Test responses

      AUTHORISE_RESPONSE = <<EOS
<?xml version="1.0" encoding="UTF-8"?>
<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
  <soap:Body>
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
  </soap:Body>
</soap:Envelope>
EOS

      AUTHORISATION_REFUSED_RESPONSE = <<EOS
<?xml version="1.0" encoding="UTF-8"?>
<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
  <soap:Body>
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
  </soap:Body>
</soap:Envelope>
EOS

      AUTHORISATION_REQUEST_INVALID_RESPONSE = <<EOS
<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
  <soap:Body>
    <soap:Fault>
      <faultcode>soap:Server</faultcode>
      <faultstring>validation 101 Invalid card number</faultstring>
    </soap:Fault>
  </soap:Body>
</soap:Envelope>
EOS
    end
  end
end
