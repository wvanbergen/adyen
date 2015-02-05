module Adyen
  module REST

    # This module implements the <b>Payment.authorise</b>, and <b>Payment.authorise3d</b>
    # API calls, and includes a custom response class to make handling the response easier.
    module AuthorisePayment

      class Request < Adyen::REST::Request

        def set_amount(currency, value)
          self['amount'] = { currency: currency, value: value }
        end

        def set_encrypted_card_data(source)
          encrypted_json = if source.respond_to?(:params)
            source.params['adyen-encrypted-data']
          elsif source.respond_to?(:[]) && source.key?('adyen-encrypted-data')
            source['adyen-encrypted-data']
          else
            source
          end

          self['additional_data.card.encrypted.json'] = encrypted_json
        end

        def set_browser_info(request)
          self['shopper_ip']                 = request.ip
          self['browser_info.accept_header'] = request['Accept'] || "text/html;q=0.9,*/*",
          self['browser_info.user_agent']    = request.user_agent
        end

        def set_3d_secure_parameters(request)
          set_browser_info(request)
          self['pa_response'] = request.params['PaRes']
          self['md']          = request.params['MD']
        end
      end

      # The Response class implements some extensions for the authorise payment call.
      # @see Adyen::REST::Response
      class Response < Adyen::REST::Response

        # Checks whether the authorisation was successful.
        # @return [Boolean] <tt>true</tt> iff the authorisation was successful, and the
        #   authorised amount can be captured.
        def authorised?
          result_code == AUTHORISED
        end

        alias_method :authorized?, :authorised?

        # Check whether the payment was refused.
        # @return [Boolean] <tt>true</tt> iff the authorisation was not successful.
        def refused?
          result_code == REFUSED
        end

        # Checks whether the result of the authorization call was RedirectShopper,
        # which means that the customer has to be redirected away from your site to
        # complete the 3Dsecure transaction.
        # @return [Boolean] <tt>true</tt> iff the shopper has to be redirected,
        #   <tt>false</tt> in any other case.
        def redirect_shopper?
          result_code == REDIRECT_SHOPPER
        end

        # Returns the result code from the transaction.
        # @return [String] The result code.
        # @see #authorised?
        # @see #refused?
        # @see #redirect_shopper?
        def result_code
          self[:result_code]
        end

        private

        AUTHORISED       = 'Authorised'.freeze
        REFUSED          = 'Refused'.freeze
        REDIRECT_SHOPPER = 'RedirectShopper'.freeze
        private_constant :AUTHORISED, :REFUSED, :REDIRECT_SHOPPER
      end

      # Generates <tt>Payment.authorise</tt> request for Adyen's webservice.
      # @param (see #authorise_payment)
      # @return [Adyen::REST::Request] The request to send
      # @see #authorise_payment
      def authorise_payment_request(attributes = {})
        Adyen::REST::AuthorisePayment::Request.new('Payment.authorise', attributes,
            prefix: 'payment_request',
            response_class: Adyen::REST::AuthorisePayment::Response,
            response_options: { prefix: 'payment_result' })
      end

      # Sends an authorise payment request to Adyen's webservice.
      # @param attributes [Hash] The attributes to include in the request.
      # @return [Adyen::REST::AuthorisePayment::Response] The response from Adyen.
      #   The response responds to <tt>.authorised?</tt> to check whether the
      #   authorization was successful.
      # @see Adyen::REST::AuthorisePayment::Response#authorised?
      def authorise_payment(attributes)
        request = authorise_payment_request(attributes)
        execute_request(request)
      end

      # Generates a <tt>Payment.authorise3d</tt> request to Adyen's webservice.
      #
      # The response differs based on the credit card uses in the transaction.
      # For some credit cards, an additional offsite step may be required to complete
      # the transaction. Check <tt>.redirect_shopper?</tt> to see if this is the case.
      # Other cards are not 3DSecure-enabled, and may immediately authorise the
      # transaction. Check <tt>.authorised?</tt> to see if this is the case.
      #
      # @param attributes [Hash] The attributes to include in the request.
      # @return [Adyen::REST::AuthorisePayment::Response] The response from Adyen.
      # @see Adyen::REST::AuthorisePayment::Response#redirect_shopper?
      # @see Adyen::REST::AuthorisePayment::Response#authorised?
      def authorise_payment_3dsecure_request(attributes = {})
        Adyen::REST::AuthorisePayment::Request.new('Payment.authorise3d', attributes,
            prefix: 'payment_request_3d',
            response_class: Adyen::REST::AuthorisePayment::Response,
            response_options: { prefix: 'payment_result' })
      end

      # Sends a 3Dsecure-enabled authorise payment request to Adyen's webservice.
      #
      # The response differs based on the credit card uses in the transaction.
      # For some credit cards, an additional offsite step may be required to complete
      # the transaction. Check <tt>.redirect_shopper?</tt> to see if this is the case.
      # Other cards are not 3DSecure-enabled, and may immediately authorise the
      # transaction. Check <tt>.authorised?</tt> to see if this is the case.
      #
      # @param attributes [Hash] The attributes to include in the request.
      # @return [Adyen::REST::AuthorisePayment::Response] The response from Adyen.
      # @see Adyen::REST::AuthorisePayment::Response#redirect_shopper?
      # @see Adyen::REST::AuthorisePayment::Response#authorised?
      def authorise_payment_3dsecure(attributes)
        request = authorise_payment_3dsecure_request(attributes)
        execute_request(request)
      end

      # Generates <tt>Payment.authorise</tt> request with recurring for Adyen's webservice.
      # @param (see #authorise_recurring_payment)
      # @return [Adyen::REST::Request] The request to send
      # @see #authorise_recurring_payment
      def authorise_recurring_payment_request(attributes={})
        Adyen::REST::AuthoriseRecurringPayment::Request.new('Payment.authorise', attributes,
            prefix: 'payment_request',
            response_class: Adyen::REST::AuthorisePayment::Response,
            response_options: { prefix: 'payment_result' })
      end

      # Sends an authorise recurring payment request to Adyen's webservice.
      # @param attributes [Hash] The attributes to include in the request.
      # @return [Adyen::REST::AuthorisePayment::Response] The response from Adyen.
      #   The response responds to <tt>.authorised?</tt> to check whether the
      #   authorization was successful.
      # @see Adyen::REST::AuthorisePayment::Response#authorised?
      def authorise_recurring_payment(attributes)
        request = authorise_recurring_payment_request(attributes)
        execute_request(request)
      end

      # Generates <tt>Payment.authorise</tt> request with recurring for Adyen's webservice.
      # This method can be called if a previous contract was established with #authorise_recurring_payment
      # @param (see #authorise_recurring_payment)
      # @return [Adyen::REST::Request] The request to send
      # @see #authorise_recurring_payment
      def reauthorise_recurring_payment_request(attributes={})
        Adyen::REST::ReauthoriseRecurringPayment::Request.new('Payment.authorise', attributes,
            prefix: 'payment_request',
            response_class: Adyen::REST::AuthorisePayment::Response,
            response_options: { prefix: 'payment_result' })
      end

      # Sends an authorise recurring payment request to Adyen's webservice.
      # This method can be called if a previous contract was established with #authorise_recurring_payment
      # @param attributes [Hash] The attributes to include in the request.
      # @return [Adyen::REST::AuthorisePayment::Response] The response from Adyen.
      #   The response responds to <tt>.authorised?</tt> to check whether the
      #   authorization was successful.
      # @see Adyen::REST::AuthorisePayment::Response#authorised?
      def reauthorise_recurring_payment(attributes)
        request = reauthorise_recurring_payment_request(attributes)
        execute_request(request)
      end

      # The Response class implements some extensions for the list recurring details call.
      # @see Adyen::REST::Response
      class ListRecurringDetailsResponse < Adyen::REST::Response
        # Returns a list of recurring details
        # @return [Array] A not empty array if there is at least a recurring detail
        def details
          list = []
          index = 0

          while !attributes["recurringDetailsResult.details.{%}.recurringDetailReference".gsub("{%}", index.to_s)].empty? do
            response = { card: {} }
            response[:recurring_detail_reference] = attributes["recurringDetailsResult.details.{%}.recurringDetailReference".gsub("{%}", index.to_s)]
            response[:creation_date]              = attributes["recurringDetailsResult.details.{%}.creationDate".gsub("{%}", index.to_s)]
            response[:variant]                    = attributes["recurringDetailsResult.details.{%}.variant".gsub("{%}", index.to_s)]
            response[:card][:holder_name]         = attributes["recurringDetailsResult.details.{%}.card.holderName".gsub("{%}", index.to_s)]
            response[:card][:expiry_month]        = attributes["recurringDetailsResult.details.{%}.card.expiryMonth".gsub("{%}", index.to_s)]
            response[:card][:expiry_year]         = attributes["recurringDetailsResult.details.{%}.card.expiryYear".gsub("{%}", index.to_s)]
            response[:card][:number]              = attributes["recurringDetailsResult.details.{%}.card.number".gsub("{%}", index.to_s)]
            list << response
            index += 1
          end

          list
        end

        # Returns a list of recurring details references
        # @return [Array] A not empty array if there is at least a recurring detail reference
        def references
          details.map { |detail| detail[:recurring_detail_reference] }
        end
      end

      # Generates <tt>Recurring.listRecurringDetails</tt> request for Adyen's webservice.
      # @param (see #list_recurring_details)
      # @return [Adyen::REST::ListRecurringDetailsPayment::Request] The request to send
      # @see #list_recurring_details
      def list_recurring_details_request(attributes = {})
        Adyen::REST::ListRecurringDetailsPayment::Request.new('Recurring.listRecurringDetails', attributes,
            prefix: 'recurring_details_request',
            response_class: Adyen::REST::AuthorisePayment::ListRecurringDetailsResponse,
            response_options: { prefix: 'recurring_details_result' })
      end

      # Sends an list recurring details request to Adyen's webservice.
      # @param attributes [Hash] The attributes to include in the request.
      # @return [Adyen::REST::AuthorisePayment::ListRecurringDetailsResponse] The response from Adyen.
      # The response responds to <tt>.details</tt> and <tt>.references</tt> with recurring data.
      # @see Adyen::REST::AuthorisePayment::ListRecurringDetailsResponse#references
      # @see Adyen::REST::AuthorisePayment::ListRecurringDetailsResponse#details
      def list_recurring_details(attributes)
        request = list_recurring_details_request(attributes)
        execute_request(request)
      end

      alias_method :authorize_payment_request, :authorise_payment_request
      alias_method :authorize_payment, :authorise_payment
      alias_method :authorize_payment_3dsecure_request, :authorise_payment_3dsecure_request
      alias_method :authorize_payment_3dsecure, :authorise_payment_3dsecure
      alias_method :reauthorize_recurring_payment_request, :reauthorise_recurring_payment_request
      alias_method :reauthorize_recurring_payment, :reauthorise_recurring_payment
    end
  end
end
