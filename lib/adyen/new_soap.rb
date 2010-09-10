module Adyen
  module SOAP
    class NewPaymentService
      LAYOUT = <<EOS
<?xml version="1.0"?>
<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
  <soap:Body>
    <ns1:authorise xmlns:ns1="http://payment.services.adyen.com">
      <ns1:paymentRequest>
        %s
      </ns1:paymentRequest>
    </ns1:authorise>
  </soap:Body>
</soap:Envelope>
EOS

      AMOUNT_PARTIAL = <<EOS
        <amount xmlns="http://payment.services.adyen.com">
          <currency xmlns="http://common.services.adyen.com">%s</currency>
          <value xmlns="http://common.services.adyen.com">%s</value>
        </amount>
EOS

      CARD_PARTIAL = <<EOS
        <card xmlns="http://payment.services.adyen.com">
          <holderName>%s</holderName>
          <number>%s</number>
          <cvc>%s</cvc>
          <expiryYear>%s</expiryYear>
          <expiryMonth>%02d</expiryMonth>
        </card>
EOS

      attr_reader :params

      def initialize(params = {})
        @params = params
      end

      def amount_partial
        AMOUNT_PARTIAL % @params[:amount].values_at(:currency, :value)
      end

      def card_partial
        card  = @params[:card].values_at(:holder_name, :number, :cvc, :expiry_year)
        card << @params[:card][:expiry_month].to_i
        CARD_PARTIAL % card
      end

      def shopper_partial
        partial = ''
        if shopper = @params[:shopper]
          if reference = shopper[:reference]
            partial << %{<shopperReference xmlns="http://payment.services.adyen.com">#{reference}</shopperReference>}
          end
          if email = shopper[:email]
            partial << %{<shopperEmail xmlns="http://payment.services.adyen.com">#{email}</shopperEmail>}
          end
          if ip = shopper[:ip]
            partial << %{<shopperIP xmlns="http://payment.services.adyen.com">#{ip}</shopperIP>}
          end
        end
        partial
      end

      def authorise_payment_request_body
        LAYOUT % (amount_partial + card_partial + shopper_partial)
      end
    end
  end
end
