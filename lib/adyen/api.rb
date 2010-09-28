require "net/https"

module Adyen
  module API
    class << self
      # Username for the HTTP Basic Authentication that Adyen uses. Your username
      # should be something like +ws@Company.MyAccount+
      # @return [String]
      attr_accessor :username

      # Password for the HTTP Basic Authentication that Adyen uses. You can choose
      # your password yourself in the user management tool of the merchant area.
      # @return [String] 
      attr_accessor :password

      attr_accessor :default_params
    end

    self.default_params = {}

    #
    # Shortcut methods
    #

    def self.authorise_payment(params = {})
      PaymentService.new(params).authorise_payment
    end

    def self.authorise_recurring_payment(params = {})
      PaymentService.new(params).authorise_recurring_payment
    end

    def self.disable_recurring_contract(params = {})
      RecurringService.new(params).disable
    end

    # TODO: the rest

    #
    # The actual classes
    #

    class SimpleSOAPClient
      # from http://curl.haxx.se/ca/cacert.pem
      CACERT = File.expand_path('../../../support/cacert.pem', __FILE__)

      def self.endpoint
        @endpoint ||= URI.parse(const_get('ENDPOINT_URI') % Adyen.environment)
      end

      attr_reader :params

      def initialize(params = {})
        @params = API.default_params.merge(params)
      end

      def call_webservice_action(action, data, response_class)
        endpoint = self.class.endpoint

        post = Net::HTTP::Post.new(endpoint.path, 'Accept' => 'text/xml', 'Content-Type' => 'text/xml; charset=utf-8', 'SOAPAction' => action)
        post.basic_auth(API.username, API.password)
        post.body = data

        request = Net::HTTP.new(endpoint.host, endpoint.port)
        request.use_ssl = true
        request.ca_file = CACERT
        request.verify_mode = OpenSSL::SSL::VERIFY_PEER

        request.start do |http|
          response_class.new(http.request(post))
        end
      end
    end

    class Response
      def self.response_attrs(*attrs)
        attrs.each do |attr|
          define_method(attr) { params[attr] }
        end
      end

      attr_reader :http_response

      def initialize(http_response)
        @http_response = http_response
      end

      # @return [Boolean] Whether or not the request was successful.
      def success?
        !http_failure?
      end

      # @return [Boolean] Whether or not the HTTP request was a success.
      def http_failure?
        !@http_response.is_a?(Net::HTTPSuccess)
      end

      def xml_querier
        @xml_querier ||= XMLQuerier.new(@http_response.body)
      end

      def params
        raise "The Adyen::API::Response#params method should be overriden in a subclass."
      end
    end

    class XMLQuerier
      NS = {
        'soap'      => 'http://schemas.xmlsoap.org/soap/envelope/',
        'payment'   => 'http://payment.services.adyen.com',
        'recurring' => 'http://recurring.services.adyen.com',
        'common'    => 'http://common.services.adyen.com'
      }

      class << self
        attr_accessor :backend

        def backend=(backend)
          @backend = backend
          class_eval do
            private
            if backend == :nokogiri
              def document_for_xml(xml)
                Nokogiri::XML::Document.parse(xml)
              end
              def perform_xpath(query)
                @node.xpath(query, NS)
              end
            else
              def document_for_xml(xml)
                REXML::Document.new(xml)
              end
              def perform_xpath(query)
                REXML::XPath.match(@node, query, NS)
              end
            end
          end
        end
      end

      begin
        require 'nokogiri'
        self.backend = :nokogiri
      rescue LoadError
        require 'rexml/document'
        self.backend = :rexml
      end

      def initialize(data)
        @node = data.is_a?(String) ? document_for_xml(data) : data
      end

      def xpath(query)
        result = self.class.new(perform_xpath(query))
        block_given? ? yield(result) : result
      end

      def text(query)
        xpath("#{query}/text()").to_s.strip
      end

      def children
        @node.first.children
      end

      def empty?
        @node.empty?
      end

      def to_s
        @node.to_s
      end

      def map(&block)
        @node.map { |n| self.class.new(n) }.map(&block)
      end
    end

    class PaymentService < SimpleSOAPClient
      ENDPOINT_URI = 'https://pal-%s.adyen.com/pal/servlet/soap/Payment'

      def authorise_payment
        make_payment_request(authorise_payment_request_body)
      end

      def authorise_recurring_payment
        make_payment_request(authorise_recurring_payment_request_body)
      end

      private

      def make_payment_request(data)
        call_webservice_action('authorise', data, AuthorizationResponse)
      end

      def authorise_payment_request_body
        content = card_partial
        content << RECURRING_PARTIAL if @params[:recurring]
        payment_request_body(content)
      end

      def authorise_recurring_payment_request_body
        content = RECURRING_PAYMENT_BODY_PARTIAL % (@params[:recurring_detail_reference] || 'LATEST')
        payment_request_body(content)
      end

      def payment_request_body(content)
        content << amount_partial
        content << shopper_partial if @params[:shopper]
        LAYOUT % [@params[:merchant_account], @params[:reference], content]
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
        @params[:shopper].map { |k, v| SHOPPER_PARTIALS[k] % v }.join("\n")
      end

      class AuthorizationResponse < Response
        response_attrs :result_code, :auth_code, :refusal_reason, :psp_reference

        AUTHORISED = 'Authorised'

        def success?
          super && params[:result_code] == AUTHORISED
        end

        alias authorized? success?

        def invalid_request?
          !fault_message.nil?
        end

        ERRORS = {
          'validation 101' => [:number, 'is not a valid creditcard number']
        }

        def errors
          errors = {}
          key, message = ERRORS[fault_message[0,14]]
          errors[key] = message
          errors
        end

        def params
          @params ||= xml_querier.xpath('//payment:authoriseResponse/payment:paymentResult') do |result|
            {
              :psp_reference  => result.text('./payment:pspReference'),
              :result_code    => result.text('./payment:resultCode'),
              :auth_code      => result.text('./payment:authCode'),
              :refusal_reason => result.text('./payment:refusalReason')
            }
          end
        end

        private

        def fault_message
          @fault_message ||= xml_querier.text('//soap:Fault/faultstring')
        end
      end
    end

    class RecurringService < SimpleSOAPClient
      ENDPOINT_URI = 'https://pal-%s.adyen.com/pal/servlet/soap/Recurring'

      # TODO: rename to list_details and make shortcut method take the only necessary param
      def list
        call_webservice_action('listRecurringDetails', list_request_body, ListResponse)
      end

      def disable
        call_webservice_action('disable', disable_request_body, DisableResponse)
      end

      private

      def list_request_body
        LIST_LAYOUT % [@params[:merchant_account], @params[:shopper][:reference]]
      end

      def disable_request_body
        if reference = @params[:recurring_detail_reference]
          reference = RECURRING_DETAIL_PARTIAL % reference
        end
        DISABLE_LAYOUT % [@params[:merchant_account], @params[:shopper][:reference], reference || '']
      end

      class DisableResponse < Response
        response_attrs :response

        def params
          @params ||= { :response => xml_querier.text('//recurring:disableResponse/recurring:result/recurring:response') }
        end
      end

      class ListResponse < Response
        response_attrs :details, :last_known_shopper_email, :shopper_reference, :creation_date

        def params
          @params ||= xml_querier.xpath('//recurring:listRecurringDetailsResponse/recurring:result') do |result|
            {
              :creation_date            => DateTime.parse(result.text('./recurring:creationDate')),
              :details                  => result.xpath('.//recurring:RecurringDetail').map { |node| parse_recurring_detail(node) },
              :last_known_shopper_email => result.text('./recurring:lastKnownShopperEmail'),
              :shopper_reference        => result.text('./recurring:shopperReference')
            }
          end
        end

        private

        # @todo add support for elv
        def parse_recurring_detail(node)
          result = {
            :recurring_detail_reference => node.text('./recurring:recurringDetailReference'),
            :variant                    => node.text('./recurring:variant'),
            :creation_date              => DateTime.parse(node.text('./recurring:creationDate'))
          }

          card = node.xpath('./recurring:card')
          if card.children.empty?
            result[:bank] = parse_bank_details(node.xpath('./recurring:bank'))
          else
            result[:card] = parse_card_details(card)
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

        def parse_bank_details(bank)
          {
            :bank_account_number => bank.text('./payment:bankAccountNumber'),
            :bank_location_id    => bank.text('./payment:bankLocationId'),
            :bank_name           => bank.text('./payment:bankName'),
            :bic                 => bank.text('./payment:bic'),
            :country_code        => bank.text('./payment:countryCode'),
            :iban                => bank.text('./payment:iban'),
            :owner_name          => bank.text('./payment:ownerName')
          }
        end
      end
    end
  end
end

########################
#
# XML template constants
#
########################

module Adyen
  module API
    class PaymentService
      LAYOUT = <<EOS
<?xml version="1.0"?>
<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
  <soap:Body>
    <payment:authorise xmlns:payment="http://payment.services.adyen.com" xmlns:recurring="http://recurring.services.adyen.com" xmlns:common="http://common.services.adyen.com">
      <payment:paymentRequest>
        <payment:merchantAccount>%s</payment:merchantAccount>
        <payment:reference>%s</payment:reference>
%s
      </payment:paymentRequest>
    </payment:authorise>
  </soap:Body>
</soap:Envelope>
EOS

      AMOUNT_PARTIAL = <<EOS
        <payment:amount>
          <common:currency>%s</common:currency>
          <common:value>%s</common:value>
        </payment:amount>
EOS

      CARD_PARTIAL = <<EOS
        <payment:card>
          <payment:holderName>%s</payment:holderName>
          <payment:number>%s</payment:number>
          <payment:cvc>%s</payment:cvc>
          <payment:expiryYear>%s</payment:expiryYear>
          <payment:expiryMonth>%02d</payment:expiryMonth>
        </payment:card>
EOS

      RECURRING_PARTIAL = <<EOS
        <recurring:recurring>
          <payment:contract>RECURRING</payment:contract>
        </recurring:recurring>
EOS

      RECURRING_PAYMENT_BODY_PARTIAL = <<EOS
        <payment:recurring>
          <payment:contract>RECURRING</payment:contract>
        </payment:recurring>
        <payment:selectedRecurringDetailReference>%s</payment:selectedRecurringDetailReference>
        <payment:shopperInteraction>ContAuth</payment:shopperInteraction>
EOS

      SHOPPER_PARTIALS = {
        :reference => '        <payment:shopperReference>%s</payment:shopperReference>',
        :email     => '        <payment:shopperEmail>%s</payment:shopperEmail>',
        :ip        => '        <payment:shopperIP>%s</payment:shopperIP>',
      }
    end

    class RecurringService
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
    end
  end
end
