module Adyen
  module API
    module Elv
      ELV_ATTRS           = [:bank_location, :bank_name, :bank_location_id, :holder_name, :number]
      MANDATORY_ELV_ATTRS = [:bank_location_id, :holder_name, :number]

      def elv_partial(options = {:recurring => true})
        validate_parameters!(:elv => MANDATORY_ELV_ATTRS)
        elv  = @params[:elv].values_at(*ELV_ATTRS)
        (options[:recurring] ? ELV_PARTIAL_RECURRING : ELV_PARTIAL) % elv
      end

      def parse_elv_details
        {
          :holder_name      => bank.text('./payment:accountHolderName'),
          :number           => bank.text('./payment:bankAccountNumber'),
          :bank_location    => bank.text('./payment:bankLocation'),
          :bank_location_id => bank.text('./payment:bankLocationId'),
          :bank_name        => bank.text('./payment:bankName')
        }
      end
    end
  end
end
