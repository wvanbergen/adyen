require 'adyen/api/simple_soap_client'
require 'adyen/api/templates/recurring_service'

module Adyen
  module API
    # This is the class that maps actions to Adyen’s Recurring SOAP service.
    #
    # It’s encouraged to use the shortcut methods on the {API} module, which abstracts away the
    # difference between this service and the {PaymentService}. Henceforth, for extensive
    # documentation you should look at the {API} documentation.
    #
    # The most important difference is that you instantiate a {RecurringService} with the parameters
    # that are needed for the call that you will eventually make.
    #
    # @example
    #  recurring = Adyen::API::RecurringService.new(:shopper => { :reference => user.id })
    #  response = recurring.disable
    #  response.success? # => true
    #
    class RecurringService < SimpleSOAPClient
      # The Adyen Recurring SOAP service endpoint uri.
      ENDPOINT_URI = 'https://pal-%s.adyen.com/pal/servlet/soap/Recurring'

      # @see API.list_recurring_details
      def list
        call_webservice_action('listRecurringDetails', list_request_body, ListResponse)
      end

      # @see API.disable_recurring_contract
      def disable
        call_webservice_action('disable', disable_request_body, DisableResponse)
      end

      # @see API.store_recurring_token
      def store_token
        call_webservice_action('storeToken', store_token_request_body, StoreTokenResponse)
      end

      private

      # The card's CVC isn't needed when tokenising details, so insert `nil'.
      def card_partial
        validate_parameters!(:card => [:holder_name, :number, :expiry_year, :expiry_month])
        card  = @params[:card].values_at(:holder_name, :number, :cvc, :expiry_year)
        card << @params[:card][:expiry_month].to_i
        CARD_PARTIAL % card
      end

      ELV_ATTRS = [:bank_location, :bank_name, :bank_location_id, :holder_name, :number]
      # The ELV - (Elektronisches Lastschriftverfahren) does not require bank_location, so insert 'nil'.
      def elv_partial
        validate_parameters!(:elv => ELV_ATTRS)
        elv  = @params[:elv].values_at(*ELV_ATTRS)
        ELV_PARTIAL % elv
      end

      def list_request_body
        validate_parameters!(:merchant_account, :shopper => [:reference])
        LIST_LAYOUT % [@params[:merchant_account], @params[:shopper][:reference]]
      end

      def disable_request_body
        validate_parameters!(:merchant_account, :shopper => [:reference])
        if reference = @params[:recurring_detail_reference]
          reference = RECURRING_DETAIL_PARTIAL % reference
        end
        DISABLE_LAYOUT % [@params[:merchant_account], @params[:shopper][:reference], reference || '']
      end

      def store_token_request_body
        validate_parameters!(:merchant_account, :shopper => [:email, :reference])
        content = []
        content << card_partial unless @params[:card].nil?
        content << elv_partial  unless @params[:elv].nil?    
        raise ArgumentError, "The required parameter 'card' or 'elv' is missing." if content.empty?    
        STORE_TOKEN_LAYOUT % [@params[:merchant_account], @params[:shopper][:reference], @params[:shopper][:email], content]
      end

      class DisableResponse < Response
        DISABLED_RESPONSES = %w{ [detail-successfully-disabled] [all-details-successfully-disabled] }

        response_attrs :response

        def success?
          super && DISABLED_RESPONSES.include?(params[:response])
        end

        alias_method :disabled?, :success?

        def params
          @params ||= { :response => xml_querier.text('//recurring:disableResponse/recurring:result/recurring:response') }
        end
      end

      class ListResponse < Response
        response_attrs :details, :last_known_shopper_email, :shopper_reference, :creation_date

        def references
          details ? details.map { |d| d[:recurring_detail_reference] } : []
        end

        def params
          @params ||= xml_querier.xpath('//recurring:listRecurringDetailsResponse/recurring:result') do |result|
            details = result.xpath('.//recurring:RecurringDetail')
            details.empty? ? {} : {
              :creation_date            => DateTime.parse(result.text('./recurring:creationDate')),
              :details                  => details.map { |node| parse_recurring_detail(node) },
              :last_known_shopper_email => result.text('./recurring:lastKnownShopperEmail'),
              :shopper_reference        => result.text('./recurring:shopperReference')
            }
          end
        end

        private

        def parse_recurring_detail(node)
          result = {
            :recurring_detail_reference => node.text('./recurring:recurringDetailReference'),
            :variant                    => node.text('./recurring:variant'),
            :creation_date              => DateTime.parse(node.text('./recurring:creationDate'))
          }

          card = node.xpath('./recurring:card')
          elv  = node.xpath('./recurring:elv')  
          bank = node.xpath('./recurring:bank')        
          
          if !card.children.empty?
            result[:card] = parse_card_details(card)
          elsif !elv.children.empty?
            result[:elv] = parse_elv_details(elv)
          else
            result[:bank] = parse_bank_details(bank)
          end
          
          result
        end

        def parse_card_details(card)
          {
            :expiry_date => Date.new(card.text('./payment:expiryYear').to_i, card.text('./payment:expiryMonth').to_i, -1),
            :holder_name => card.text('./payment:holderName'),
            :number      => card.text('./payment:number')
          }
        end

        def parse_elv_details(elv)
          {
            :holder_name      => elv.text('./payment:accountHolderName'),
            :number           => elv.text('./payment:bankAccountNumber'),
            :bank_location    => elv.text('./payment:bankLocation'),
            :bank_location_id => elv.text('./payment:bankLocationId'),
            :bank_name        => elv.text('./payment:bankName')
          }
        end

        def parse_bank_details(bank)
          {
            :number           => bank.text('./payment:bankAccountNumber'),
            :bank_location_id => bank.text('./payment:bankLocationId'),
            :bank_name        => bank.text('./payment:bankName'),
            :bic              => bank.text('./payment:bic'),
            :country_code     => bank.text('./payment:countryCode'),
            :iban             => bank.text('./payment:iban'),
            :holder_name      => bank.text('./payment:ownerName')
          }
        end
      end

      class StoreTokenResponse < Response
        response_attrs :response, :recurring_detail_reference

        def recurring_detail_reference
          params[:recurring_detail_reference]
        end

        def success?
          super && params[:response] == 'Success'
        end

        alias_method :stored?, :success?

        def params
          @params ||= {
            :response => xml_querier.text('//recurring:storeTokenResponse/recurring:result/recurring:result'),
            :reference =>  xml_querier.text('//recurring:storeTokenResponse/recurring:result/recurring:rechargeReference'),
            :recurring_detail_reference => xml_querier.text('//recurring:storeTokenResponse/recurring:result/recurring:recurringDetailReference')
          }
        end
      end
    end
  end
end
