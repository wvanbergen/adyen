module Adyen
  module API
    class PaymentService < SimpleSOAPClient
      class << self
        private

        def modification_request(method, body = nil)
          return <<EOS
    <payment:#{method} xmlns:payment="http://payment.services.adyen.com" xmlns:recurring="http://recurring.services.adyen.com" xmlns:common="http://common.services.adyen.com">
      <payment:modificationRequest>
        <payment:merchantAccount>%s</payment:merchantAccount>
        <payment:originalReference>%s</payment:originalReference>
        #{body}
      </payment:modificationRequest>
    </payment:#{method}>
EOS
        end

        def modification_request_with_amount(method)
          modification_request(method, <<EOS)
        <payment:modificationAmount>
          <common:currency>%s</common:currency>
          <common:value>%s</common:value>
        </payment:modificationAmount>
EOS
        end
      end

      # @private
      CAPTURE_LAYOUT          = modification_request_with_amount(:capture)
      # @private
      REFUND_LAYOUT           = modification_request_with_amount(:refund)
      # @private
      CANCEL_LAYOUT           = modification_request(:cancel)
      # @private
      CANCEL_OR_REFUND_LAYOUT = modification_request(:cancelOrRefund)

      # @private
      LAYOUT = <<EOS
    <payment:authorise xmlns:payment="http://payment.services.adyen.com" xmlns:recurring="http://recurring.services.adyen.com" xmlns:common="http://common.services.adyen.com">
      <payment:paymentRequest>
        <payment:merchantAccount>%s</payment:merchantAccount>
        <payment:reference>%s</payment:reference>
%s
      </payment:paymentRequest>
    </payment:authorise>
EOS

      # @private
      AMOUNT_PARTIAL = <<EOS
        <payment:amount>
          <common:currency>%s</common:currency>
          <common:value>%s</common:value>
        </payment:amount>
EOS

      # @private
      CARD_PARTIAL = <<EOS
        <payment:card>
          <payment:holderName>%s</payment:holderName>
          <payment:number>%s</payment:number>
          <payment:cvc>%s</payment:cvc>
          <payment:expiryYear>%s</payment:expiryYear>
          <payment:expiryMonth>%02d</payment:expiryMonth>
        </payment:card>
EOS

      # @private
      INSTALLMENTS_PARTIAL = <<EOS
        <payment:installments>
          <common:value>%s</common:value>
        </payment:installments>
EOS

      # @private
      ENCRYPTED_CARD_PARTIAL = <<EOS
        <additionalAmount xmlns="http://payment.services.adyen.com" xsi:nil="true" />
        <additionalData xmlns="http://payment.services.adyen.com">
          <entry>
            <key xsi:type="xsd:string">card.encrypted.json</key>
            <value xsi:type="xsd:string">%s</value>
          </entry>
        </additionalData>
EOS

      # @private
      ENABLE_RECURRING_CONTRACTS_PARTIAL = <<EOS
        <payment:recurring>
          <payment:contract>RECURRING,ONECLICK</payment:contract>
        </payment:recurring>
EOS

      # @private
      RECURRING_PAYMENT_BODY_PARTIAL = <<EOS
        <payment:recurring>
          <payment:contract>RECURRING</payment:contract>
        </payment:recurring>
        <payment:selectedRecurringDetailReference>%s</payment:selectedRecurringDetailReference>
        <payment:shopperInteraction>ContAuth</payment:shopperInteraction>
EOS

      # @private
      ONE_CLICK_PAYMENT_BODY_PARTIAL = <<EOS
        <payment:recurring>
          <payment:contract>ONECLICK</payment:contract>
        </payment:recurring>
        <payment:selectedRecurringDetailReference>%s</payment:selectedRecurringDetailReference>
        <payment:card>
          <payment:cvc>%s</payment:cvc>
        </payment:card>
EOS

      # @private
      SHOPPER_PARTIALS = {
        :reference => '        <payment:shopperReference>%s</payment:shopperReference>',
        :email     => '        <payment:shopperEmail>%s</payment:shopperEmail>',
        :ip        => '        <payment:shopperIP>%s</payment:shopperIP>',
        :statement => '        <payment:shopperStatement>%s</payment:shopperStatement>',
      }

      # @private
      FRAUD_OFFSET_PARTIAL = '<payment:fraudOffset>%s</payment:fraudOffset>'
    end
  end
end
