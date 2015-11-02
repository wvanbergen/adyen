require 'adyen/hpp/signature'
require 'cgi'

module Adyen
  module HPP

    class Request
      attr_reader :client, :skin

      # Initialize the HPP request
      #
      # @param client [Adyen::HPP::Client] The HPP client that sets the environment
      # @param skin [Hash|String] A skin hash in the same format that is returned by
      #    Adyen::Configuration.register_form_skin, or the name of a registered skin
      def initialize(client, skin = nil)
        @client = client
        @skin = skin || Adyen.configuration.default_skin
        @skin = Adyen.configuration.form_skin_by_name(@skin) || {} unless skin.is_a?(Hash)
      end

      # Transforms the payment parameters hash to be in the correct format. It will also
      # include the Adyen::Configuration#default_form_params hash and it will
      # include the +:skin_code+ and +:shared_secret+ parameters and the default attributes
      # of the skin that is set, unless the skin code and the shared secret are supplied
      # directly in the parameters.
      #
      # @param [Hash] parameters The payment parameters. The parameters set in the
      #    {Adyen::Configuration#default_form_params} hash will be included automatically.
      # @return [Hash] Completed and formatted payment parameters.
      # @raise [ArgumentError] Thrown if some parameter health check fails.
      def payment_parameters(parameters = {})
        raise ArgumentError, "Cannot generate form: parameters should be a hash!" unless parameters.is_a?(Hash)
        formatted_parameters = Adyen.configuration.default_form_params.merge(parameters)

        unless formatted_parameters[:skin_code] && formatted_parameters[:shared_secret]
          if formatted_parameters[:skin]
            @skin = Adyen.configuration.form_skin_by_name(formatted_parameters.delete(:skin)) || {}
          end
          formatted_parameters[:skin_code] = skin[:skin_code]
          formatted_parameters[:shared_secret] = skin[:shared_secret]
          formatted_parameters.merge!(skin[:default_form_params] || {})
        end

        raise ArgumentError, "Cannot calculate payment request signature without shared secret!" unless formatted_parameters[:shared_secret]
        raise ArgumentError, "Cannot generate form: :currency code attribute not found!"         unless formatted_parameters[:currency_code]
        raise ArgumentError, "Cannot generate form: :payment_amount code attribute not found!"   unless formatted_parameters[:payment_amount]
        raise ArgumentError, "Cannot generate form: :merchant_account attribute not found!"      unless formatted_parameters[:merchant_account]
        raise ArgumentError, "Cannot generate form: :skin_code attribute not found!"             unless formatted_parameters[:skin_code]

        formatted_parameters[:recurring_contract] = 'RECURRING' if formatted_parameters.delete(:recurring) == true
        formatted_parameters[:order_data]         = Adyen::Util.gzip_base64(formatted_parameters.delete(:order_data_raw)) if formatted_parameters[:order_data_raw]
        formatted_parameters[:ship_before_date]   = Adyen::Util.format_date(formatted_parameters[:ship_before_date])
        formatted_parameters[:session_validity]   = Adyen::Util.format_timestamp(formatted_parameters[:session_validity])
        formatted_parameters
      end

      # Transforms and flattens payment parameters to be in the correct format which is understood and accepted by adyen
      #
      # @param [Hash] parameters Formatted payment parameters including shared secret.
      # @return [Hash] The payment parameters, with camelized and prefixed key, stringified values,
      #    the +:merchant_signature+ parameter set and the shared secret removed.
      def flat_payment_parameters(parameters = {})
        Adyen::HPP::Signature.sign(Adyen::Util.flatten(payment_parameters(parameters)))
      end

      # Returns an absolute URL to the Adyen payment system, with the payment parameters included
      # as GET parameters in the URL. The URL also depends on the Adyen enviroment of the HPP client.
      #
      # The payment parameters that are provided to this method will be merged with the
      # {Adyen::Configuration#default_form_params} hash. The default parameter values will be
      # overrided if another value is provided to this method.
      #
      # You do not have to provide the +:merchant_sig+ parameter: it will be calculated automatically.
      #
      # Note that Internet Explorer has a maximum length for URLs it can handle (2083 characters).
      # Make sure that the URL is not longer than this limit if you want your site to work in IE.
      #
      # @example
      #
      #    def pay
      #      # Generate a URL to redirect to Adyen's payment system.
      #      hpp_client = Adyen::HPP::Client.new(:test)
      #      adyen_url = hpp_client.new_request(:my_skin).redirect_url(:currency_code => 'USD',
      #            :payment_amount => 1000, merchant_account => 'MyMerchant', ... )
      #
      #      respond_to do |format|
      #        format.html { redirect_to(adyen_url) }
      #      end
      #    end
      #
      # @param [Hash] parameters The payment parameters to include in the payment request.
      # @return [String] An absolute URL to redirect to the Adyen payment system.
      def redirect_url(parameters = {})
        client.url + '?' + flat_payment_parameters(parameters).map { |(k, v)|
          "#{CGI.escape(k)}=#{CGI.escape(v)}"
        }.join('&')
      end

      # @see Adyen::HPP::Request.redirect_url
      #
      # Returns an absolute URL very similar to the one returned by Adyen::HPP::Request.redirect_url
      # except that it uses the directory.shtml call which returns a list of all available
      # payment methods
      #
      # @param [Hash] parameters The payment parameters to include in the payment request.
      # @return [String] An absolute URL to redirect to the Adyen payment system.
      def payment_methods_url(parameters = {})
        client.url(:directory) + '?' + flat_payment_parameters(parameters).map { |(k, v)|
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
      #    <% hpp_client = Adyen::HPPL::Client.new(:test) %>
      #    <% form_tag(hpp_client.url, authenticity_token: false, enforce_utf8: false) do %>
      #      <%= hpp_client.new_request(:my_skin).hidden_fields(:currency_code => 'USD',
      #            :payment_amount => 1000, ...) %>
      #      <%= submit_tag("Pay invoice")
      #    <% end %>
      #
      # @param [Hash] parameters The payment parameters to include in the payment request.
      # @return [String] An HTML snippet that can be included in a form that POSTs to the
      #       Adyen payment system.
      def hidden_fields(parameters = {})

        # Generate a hidden input tag per parameter, join them by newlines.
        form_str = flat_payment_parameters(parameters).map { |key, value|
          "<input type=\"hidden\" name=\"#{CGI.escapeHTML(key)}\" value=\"#{CGI.escapeHTML(value)}\" />"
        }.join("\n")

        form_str.respond_to?(:html_safe) ? form_str.html_safe : form_str
      end
    end
  end
end