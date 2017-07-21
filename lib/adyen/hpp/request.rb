require 'adyen/hpp/signature'
require 'adyen/util'
require 'cgi'

module Adyen
  module HPP

    class Request
      attr_accessor :parameters
      attr_writer :skin, :environment, :shared_secret

      MANDATORY_ATTRIBUTES = %i(currency_code payment_amount merchant_account skin_code ship_before_date session_validity).freeze

      # Initialize the HPP request
      #
      # @param [Hash] parameters The payment parameters
      #    You must not provide the +:merchant_sig+ parameter: it will be calculated automatically.
      # @param [Hash|String] skin A skin hash in the same format that is returned by
      #    Adyen::Configuration.register_form_skin, or the name of a registered skin.
      #    When not set, the default skin specified in the configuration will be used.
      # @param [String] environment The Adyen environment to use.
      #    When not set, the environment specified in the configuration will be used.
      # @param [String] shared_secret The shared secret to use for signing the request.
      #    When not set, the shared secret of the skin will be used.
      def initialize(parameters, skin: nil, environment: nil, shared_secret: nil)
        @parameters, @skin, @environment, @shared_secret = parameters, skin, environment, shared_secret
        @skin = Adyen.configuration.form_skin_by_name(@skin) unless skin.nil? || skin.is_a?(Hash)
      end

      # Returns the Adyen skin to use for the request, in the same format that is
      #   returned by Adyen::Configuration.register_form_skin
      #
      # @return [Hash] skin if set, configuration default otherwise
      def skin
        @skin || Adyen.configuration.form_skin_by_name(Adyen.configuration.default_skin) || {}
      end

      # Returns the Adyen environment the request will be directed to
      #
      # @return [String] environment if set, configuration default otherwise
      def environment
        @environment || Adyen.configuration.environment
      end

      # Returns the shared secret to use for signing the request
      #
      # @return [String] shared secret if set, the skin's shared secret otherwise
      def shared_secret
        @shared_secret || skin[:shared_secret]
      end

      # Returns the DOMAIN of the Adyen payment system, adjusted for an Adyen environment.
      #
      # @return [String] The domain of the Adyen payment system that can be used
      #    for payment forms or redirects.
      # @see Adyen::HPP::Request.redirect_url
      def domain
        Adyen.configuration.payment_flow_domain || HPP_DOMAIN % [environment.to_s]
      end

      # Returns the URL of the Adyen payment system, adjusted for an Adyen environment.
      #
      # @param [String] payment_flow The Adyen payment type to use. This parameter can be
      #    left out, in which case the default payment type will be used.
      # @return [String] The absolute URL of the Adyen payment system that can be used
      #    for payment forms or redirects.
      # @see Adyen::HPP::Request.domain
      # @see Adyen::HPP::Request.redirect_url
      # @see Adyen::HPP::Request.payment_methods_url
      def url(payment_flow = nil)
        payment_flow ||= Adyen.configuration.payment_flow
        HPP_URL % [domain, payment_flow.to_s]
      end

      # Transforms the payment parameters hash to be in the correct format. It will also
      # include the Adyen::Configuration#default_form_params hash and it will
      # include the +:skin_code+ parameter and the default attributes of the skin
      # Any default parameter value will be overrided if another value is provided in the request.
      #
      # @return [Hash] Completed and formatted payment parameters.
      # @raise [ArgumentError] Thrown if some parameter health check fails.
      def formatted_parameters
        raise ArgumentError, "Cannot generate request: parameters should be a hash!" unless parameters.is_a?(Hash)

        formatted_parameters = parameters
        default_form_parameters = Adyen.configuration.default_form_params
        unless skin.empty?
          formatted_parameters[:skin_code] ||= skin[:skin_code]
          default_form_parameters = default_form_parameters.merge(skin[:default_form_params] || {})
        end
        formatted_parameters = default_form_parameters.merge(formatted_parameters)

        MANDATORY_ATTRIBUTES.each do |attribute|
          raise ArgumentError, "Cannot generate request: :#{attribute} attribute not found!" unless formatted_parameters[attribute]
        end

        formatted_parameters[:recurring_contract] = 'RECURRING' if formatted_parameters.delete(:recurring) == true
        formatted_parameters[:order_data]         = Adyen::Util.gzip_base64(formatted_parameters.delete(:order_data_raw)) if formatted_parameters[:order_data_raw]
        formatted_parameters[:ship_before_date]   = Adyen::Util.format_date(formatted_parameters[:ship_before_date])
        formatted_parameters[:session_validity]   = Adyen::Util.format_timestamp(formatted_parameters[:session_validity])
        formatted_parameters
      end

      # Transforms and flattens payment parameters to be in the correct format which is understood and accepted by adyen
      #
      # @return [Hash] The payment parameters, with camelized and prefixed key, stringified values and
      #    the +:merchant_signature+ parameter set.
      def flat_payment_parameters
        Adyen::HPP::Signature.sign(Adyen::Util.flatten(formatted_parameters), shared_secret)
      end

      # Returns an absolute URL to the Adyen payment system, with the payment parameters included
      # as GET parameters in the URL. The URL also depends on the Adyen enviroment
      #
      # Note that Internet Explorer has a maximum length for URLs it can handle (2083 characters).
      # Make sure that the URL is not longer than this limit if you want your site to work in IE.
      #
      # @example
      #
      #    def pay
      #      # Generate a URL to redirect to Adyen's payment system.
      #      payment_parameters = {
      #        :currency_code => 'USD',
      #        :payment_amount => 1000,
      #        :merchant_account => 'MyMerchant',
      #        ...
      #      }
      #      hpp_request = Adyen::HPP::Request.new(payment_parameters, skin: :my_skin, environment: :test)
      #
      #      respond_to do |format|
      #        format.html { redirect_to(hpp_request.redirect_url) }
      #      end
      #    end
      #
      # @return [String] An absolute URL to redirect to the Adyen payment system.
      def redirect_url
        url + '?' + flat_payment_parameters.map { |(k, v)|
          "#{CGI.escape(k)}=#{CGI.escape(v)}"
        }.join('&')
      end

      # @see Adyen::HPP::Request.redirect_url
      #
      # Returns an absolute URL very similar to the one returned by Adyen::HPP::Request.redirect_url
      # except that it uses the directory.shtml call which returns a list of all available
      # payment methods
      #
      # @return [String] An absolute URL to redirect to the Adyen payment system.
      def payment_methods_url
        url(:directory) + '?' + flat_payment_parameters.map { |(k, v)|
          "#{CGI.escape(k)}=#{CGI.escape(v)}"
        }.join('&')
      end

      # Returns a HTML snippet of hidden INPUT tags with the provided payment parameters.
      # The snippet can be included in a payment form that POSTs to the Adyen payment system.
      #
      # The payment parameters that are provided to this method will be merged with the
      # {Adyen::Configuration#default_form_params} hash. The default parameter values will be
      # overrided if another value is provided to this method.
      #
      # You do not have to provide the +:merchant_sig+ parameter: it will be calculated automatically.
      #
      # @example
      #
      #      <%
      #        payment_parameters = {
      #          :currency_code => 'USD',
      #          :payment_amount => 1000,
      #          :merchant_account => 'MyMerchant',
      #          ...
      #        }
      #        hpp_request = Adyen::HPP::Request.new(payment_parameters, skin: :my_skin, environment: :test)
      #     %>
      #
      #    <%= form_tag(hpp_request.url, authenticity_token: false, enforce_utf8: false) do %>
      #      <%= hpp_request.hidden_fields %>
      #      <%= submit_tag("Pay invoice")
      #    <% end %>
      #
      # @return [String] An HTML snippet that can be included in a form that POSTs to the
      #    Adyen payment system.
      def hidden_fields

        # Generate a hidden input tag per parameter, join them by newlines.
        form_str = flat_payment_parameters.map { |key, value|
          "<input type=\"hidden\" name=\"#{CGI.escapeHTML(key)}\" value=\"#{CGI.escapeHTML(value)}\" />"
        }.join("\n")

        form_str.respond_to?(:html_safe) ? form_str.html_safe : form_str
      end
    end
  end
end
