module Adyen
  module API
    class PayoutService < SimpleSOAPClient
      # @private
      LAYOUT = <<EOS
<storeDetail xmlns="http://payout.services.adyen.com">
  <request>
    <merchantAccount>%s</merchantAccount>
    %s
    </request>
</storeDetail>
EOS

      # @private
      BANK_PARTIAL = <<EOS
<bank>
  <iban xmlns="http://payment.services.adyen.com">%s</iban>
  <bic xmlns="http://payment.services.adyen.com">%s</bic>
  <bankName xmlns="http://payment.services.adyen.com">%s</bankName>
  <countryCode xmlns="http://payment.services.adyen.com">%s</countryCode>
  <ownerName xmlns="http://payment.services.adyen.com">%s</ownerName>
</bank>
EOS

      # @private
      ENABLE_RECURRING_PAYOUT_CONTRACT_PARTIAL = <<EOS
<recurring>
  <contract xmlns="http://payment.services.adyen.com">PAYOUT</contract>
</recurring>
EOS

      # @private
      SHOPPER_PARTIALS = {
        :reference => '<shopperReference>%s</shopperReference>',
        :email     => '<shopperEmail>%s</shopperEmail>'
      }
    end
  end
end
