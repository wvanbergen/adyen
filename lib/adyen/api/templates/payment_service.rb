module Adyen
  module API
    class PaymentService < SimpleSOAPClient
      class << self
        private

        def modification_request(method, body = nil)
          <<-EOXML
            <payment:#{method} xmlns:payment="http://payment.services.adyen.com" xmlns:recurring="http://recurring.services.adyen.com" xmlns:common="http://common.services.adyen.com">
              <payment:modificationRequest>
                <payment:merchantAccount>%s</payment:merchantAccount>
                <payment:originalReference>%s</payment:originalReference>
                #{body}
              </payment:modificationRequest>
            </payment:#{method}>
          EOXML
        end

        def modification_request_with_amount(method)
          modification_request(method, <<-EOXML)
            <payment:modificationAmount>
              <common:currency>%s</common:currency>
              <common:value>%s</common:value>
            </payment:modificationAmount>
          EOXML
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
      LAYOUT = <<-EOXML
        <payment:authorise xmlns:payment="http://payment.services.adyen.com" xmlns:recurring="http://recurring.services.adyen.com" xmlns:common="http://common.services.adyen.com">
          <payment:paymentRequest>
            <payment:merchantAccount>%s</payment:merchantAccount>
            <payment:reference>%s</payment:reference>
            %s
          </payment:paymentRequest>
        </payment:authorise>
      EOXML

      # @private
      AMOUNT_PARTIAL = <<-EOXML
        <payment:amount>
          <common:currency>%s</common:currency>
          <common:value>%s</common:value>
        </payment:amount>
      EOXML

      # @private
      CARD_PARTIAL = <<-EOXML
        <payment:card>
          <payment:holderName>%s</payment:holderName>
          <payment:number>%s</payment:number>
          <payment:expiryYear>%s</payment:expiryYear>
          <payment:expiryMonth>%02d</payment:expiryMonth>
          %s
        </payment:card>
      EOXML

      # @private
      CARD_CVC_PARTIAL = <<-EOXML
        <payment:cvc>%s</payment:cvc>
      EOXML

      # @private
      ONE_CLICK_CARD_PARTIAL = <<-EOXML
        <payment:card>
          <payment:cvc>%s</payment:cvc>
        </payment:card>
      EOXML

      # @private
      INSTALLMENTS_PARTIAL = <<-EOXML
        <payment:installments>
          <common:value>%s</common:value>
        </payment:installments>
      EOXML

      SOCIAL_SECURITY_NUMBER_PARTIAL = <<-EOXML
        <payment:socialSecurityNumber>%s</payment:socialSecurityNumber>
      EOXML

     # @private
      DELIVERY_DATE_PARTIAL = <<-EOXML
        <deliveryDate xmlns="http://payment.services.adyen.com">%s</deliveryDate>
      EOXML

      # @private
      SELECTED_BRAND_PARTIAL = <<-EOXML
        <payment:selectedBrand>%s</payment:selectedBrand>
      EOXML

      # @private
      SHOPPER_NAME_PARTIAL = <<-EOXML
        <payment:shopperName>
          <common:firstName>%s</common:firstName>
          <common:lastName>%s</common:lastName>
        </payment:shopperName>
      EOXML

      # @private
      SHOPPER_STATEMENT = <<-EOXML
        <payment:shopperStatement>%s</payment:shopperStatement>
      EOXML

      # @private
      ENCRYPTED_CARD_PARTIAL = <<-EOXML
        <additionalAmount xmlns="http://payment.services.adyen.com" xsi:nil="true" />
        <additionalData xmlns="http://payment.services.adyen.com">
          <entry>
            <key xsi:type="xsd:string">card.encrypted.json</key>
            <value xsi:type="xsd:string">%s</value>
          </entry>
        </additionalData>
      EOXML

      # @private
      ENABLE_RECURRING_CONTRACTS_PARTIAL = <<-EOXML
        <payment:recurring>
          <payment:contract>RECURRING,ONECLICK</payment:contract>
        </payment:recurring>
      EOXML

      # @private
      RECURRING_PAYMENT_BODY_PARTIAL = <<-EOXML
        <payment:recurring>
          <payment:contract>RECURRING</payment:contract>
        </payment:recurring>
        <payment:selectedRecurringDetailReference>%s</payment:selectedRecurringDetailReference>
        <payment:shopperInteraction>ContAuth</payment:shopperInteraction>
      EOXML

      # @private
      ONE_CLICK_PAYMENT_BODY_PARTIAL = <<-EOXML
        <payment:recurring>
          <payment:contract>ONECLICK</payment:contract>
        </payment:recurring>
        <payment:selectedRecurringDetailReference>%s</payment:selectedRecurringDetailReference>
      EOXML

      # @private
      SHOPPER_PARTIALS = {
        :reference => '        <payment:shopperReference>%s</payment:shopperReference>',
        :email     => '        <payment:shopperEmail>%s</payment:shopperEmail>',
        :ip        => '        <payment:shopperIP>%s</payment:shopperIP>',
        :statement => '        <payment:shopperStatement>%s</payment:shopperStatement>',
      }

      # @private
      FRAUD_OFFSET_PARTIAL = '<payment:fraudOffset>%s</payment:fraudOffset>'

      # @private
      CAPTURE_DELAY_PARTIAL = '<payment:captureDelayHours>%s</payment:captureDelayHours>'
    end
  end
end
