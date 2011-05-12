module Adyen
  module API
    class RecurringService < SimpleSOAPClient
      # @private
      LIST_LAYOUT = <<EOS
    <recurring:listRecurringDetails xmlns:payment="http://payment.services.adyen.com" xmlns:recurring="http://recurring.services.adyen.com">
      <recurring:request>
        <recurring:recurring>
          <payment:contract>RECURRING</payment:contract>
        </recurring:recurring>
        <recurring:merchantAccount>%s</recurring:merchantAccount>
        <recurring:shopperReference>%s</recurring:shopperReference>
      </recurring:request>
    </recurring:listRecurringDetails>
EOS

      # @private
      DISABLE_LAYOUT = <<EOS
    <recurring:disable xmlns:recurring="http://recurring.services.adyen.com">
      <recurring:request>
        <recurring:merchantAccount>%s</recurring:merchantAccount>
        <recurring:shopperReference>%s</recurring:shopperReference>
        %s
      </recurring:request>
    </recurring:disable>
EOS

      # @private
      RECURRING_DETAIL_PARTIAL = <<EOS
        <recurring:recurringDetailReference>%s</recurring:recurringDetailReference>
EOS

      STORE_TOKEN_LAYOUT = <<EOS
    <recurring:storeToken xmlns:recurring="http://recurring.services.adyen.com" xmlns:payment="http://payment.services.adyen.com">
      <recurring:request>
        <recurring:recurring>
          <payment:contract>RECURRING</payment:contract>
        </recurring:recurring>
        <recurring:merchantAccount>%s</recurring:merchantAccount>
        <recurring:shopperReference>%s</recurring:shopperReference>
        <recurring:shopperEmail>%s</recurring:shopperEmail>
        %s
      </recurring:request>
    </recurring:storeToken>
EOS

      # @private
      CARD_PARTIAL = <<EOS
        <recurring:card>
          <payment:holderName>%s</payment:holderName>
          <payment:number>%s</payment:number>
          <payment:cvc>%s</payment:cvc>
          <payment:expiryYear>%s</payment:expiryYear>
          <payment:expiryMonth>%02d</payment:expiryMonth>
        </recurring:card>
EOS
    end
  end
end
