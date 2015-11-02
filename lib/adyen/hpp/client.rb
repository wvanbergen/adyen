module Adyen
  module HPP

    class Client
      attr_reader :environment, :skin

      # Initialize the HPP client
      #
      # @param [String] environment The Adyen environment to use. This parameter can be
      #    left out, in which case the 'current' environment will be used.
      # @param [Hash|String] skin A skin hash in the same format that is returned by
      #    Adyen::Configuration.register_form_skin, or the name of a registered skin
      def initialize(environment = nil, skin = nil)
        @environment = environment || Adyen.configuration.environment
        @skin = skin || Adyen.configuration.default_skin
        @skin = Adyen.configuration.form_skin_by_name(@skin) || {} unless skin.is_a?(Hash)
      end

      # Returns the DOMAIN of the Adyen payment system, adjusted for an Adyen environment.
      #
      # @return [String] The domain of the Adyen payment system that can be used
      #    for payment forms or redirects.
      # @see Adyen::HPP::Request.redirect_url
      def domain
        (Adyen.configuration.payment_flow_domain || HPP_DOMAIN) % [environment.to_s]
      end

      # Returns the URL of the Adyen payment system, adjusted for an Adyen environment.
      #
      # @param [String] payment_flow The Adyen payment type to use. This parameter can be
      #    left out, in which case the default payment type will be used.
      # @return [String] The absolute URL of the Adyen payment system that can be used
      #    for payment forms or redirects.
      # @see Adyen::HPP::CLient.domain
      # @see Adyen::HPP::Request.redirect_url
      # @see Adyen::HPP::Request.payment_methods_url
      def url(payment_flow = nil)
        payment_flow ||= Adyen.configuration.payment_flow
        HPP_URL % [domain, payment_flow.to_s]
      end

      # Returns a new request object that can be used to generate a redirect URL or
      # a set of hidden fields for an HPP request
      #
      # @param skin [Hash|String] A skin hash in the same format that is returned by
      #    Adyen::Configuration.register_form_skin, or the name of a registered skin
      # @return [Adyen::HPP::Request] A new request object for this client
      def new_request(skin = nil)
        Adyen::HPP::Request.new(self, skin || self.skin)
      end
    end
  end
end