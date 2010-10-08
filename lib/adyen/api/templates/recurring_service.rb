module Adyen
  module API
    class RecurringService < SimpleSOAPClient
      LIST_LAYOUT = <<EOS
<?xml version="1.0"?>
<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
  <soap:Body>
    <recurring:listRecurringDetails xmlns:recurring="http://recurring.services.adyen.com">
      <recurring:request>
        <recurring:recurring>
          <recurring:contract>RECURRING</recurring:contract>
        </recurring:recurring>
        <recurring:merchantAccount>%s</recurring:merchantAccount>
        <recurring:shopperReference>%s</recurring:shopperReference>
      </recurring:request>
    </recurring:listRecurringDetails>
  </soap:Body>
</soap:Envelope>
EOS

      DISABLE_LAYOUT = <<EOS
<?xml version="1.0"?>
<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
  <soap:Body>
    <recurring:disable xmlns:recurring="http://recurring.services.adyen.com">
      <recurring:request>
        <recurring:merchantAccount>%s</recurring:merchantAccount>
        <recurring:shopperReference>%s</recurring:shopperReference>
        %s
      </recurring:request>
    </recurring:disable>
  </soap:Body>
</soap:Envelope>
EOS

      RECURRING_DETAIL_PARTIAL = <<EOS
        <recurring:recurringDetailReference>%s</recurring:recurringDetailReference>
EOS
    
    # Test responses

      DISABLE_RESPONSE = <<EOS
<?xml version="1.0"?>
<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
  <soap:Body>
    <ns1:disableResponse xmlns:ns1="http://recurring.services.adyen.com">
      <ns1:result>
        <response xmlns="http://recurring.services.adyen.com">
          %s
        </response>
      </ns1:result>
    </ns1:disableResponse>
  </soap:Body>
</soap:Envelope>
EOS
    end
  end
end
