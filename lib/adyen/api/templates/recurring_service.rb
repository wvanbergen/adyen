module Adyen
  module API
    class RecurringService < SimpleSOAPClient
      # @private
      LIST_LAYOUT = <<EOS
    <recurring:listRecurringDetails xmlns:recurring="http://recurring.services.adyen.com">
      <recurring:request>
        <recurring:recurring>
          <recurring:contract>RECURRING</recurring:contract>
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
    end
  end
end
