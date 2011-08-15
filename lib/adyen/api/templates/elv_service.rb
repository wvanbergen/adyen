module Adyen
  module API
    module Elv
      # Electronic bank debit in Germany. Semi real-time payment method.
      ELV_PARTIAL = <<-EOS
        <payment:elv>
          <payment:bankLocation>%s</payment:bankLocation>
          <payment:bankName>%s</payment:bankName>
          <payment:bankLocationId>%s</payment:bankLocationId>
          <payment:accountHolderName>%s</payment:accountHolderName>
          <payment:bankAccountNumber>%02d</payment:bankAccountNumber>
        </payment:elv>
      EOS

      ELV_PARTIAL_RECURRING = <<-EOS
        <recurring:elv>
          <payment:bankLocation>%s</payment:bankLocation>
          <payment:bankName>%s</payment:bankName>
          <payment:bankLocationId>%s</payment:bankLocationId>
          <payment:accountHolderName>%s</payment:accountHolderName>
          <payment:bankAccountNumber>%02d</payment:bankAccountNumber>
        </recurring:elv>
      EOS
    end
  end
end
