require 'adyen/base'
require 'adyen/rest/client'
require 'adyen/rest/signature'

module Adyen

  # The Adyen::REST module allows you to interact with Adyen's REST API.
  #
  # The primary method here is {Adyen::REST.session}, which will yield a
  # {Adyen::REST::Client} which you can use to send API requests.
  #
  # If you need more than one client instance, for instance because you
  # have multiple acounts set up with different permissions, you can instantiate
  # clients yourself using {Adyen::REST::Client.new}
  #
  # @example Using the singleton Client instance
  #
  #     Adyen::REST.session do |client|
  #       client.http.read_timeout = 5
  #       response = client.api_request(...)
  #       # ...
  #     end
  #
  # @example Using a your own Client instance
  #
  #     Adyen::REST::Client.new('test', 'username', 'password').session do |client|
  #       client.http.read_timeout = 5
  #       response = client.api_request(...)
  #       # ...
  #     end
  #
  #
  # @see Adyen::REST.session Use Adyen::REST.session to run code against the API.
  # @see Adyen::REST::Client Adyen::REST::Client implements the actual API calls.
  module REST

    # Provides a singelton REST API client this is configured using the values in
    # <tt>Adyen.configuration</tt>.
    #
    # @param options [Hash] (see Adyen::REST::Client#initialize)
    # @return [Adyen::REST::Client] A configured client instance
    # @see .session
    # @see Adyen::REST::Client.new To instantiate Clients yourself, in case you need more than one.
    def self.client
      Adyen::REST::Client.new(
        Adyen.configuration.environment,
        Adyen.configuration.api_username,
        Adyen.configuration.api_password,
        Adyen.configuration.merchant_specific_endpoint
      )
    end

    # Exectutes a session against the Adyen REST API.
    #
    # It will use a standard client from {Adyen::REST.client}, or it uses a provided client.
    # The client will be yielded to the block, and will be closed after the block is finisged
    #
    # @param client [Adyen::REST::Client] A custom API client if a default one won't do.
    # @yield The provided block will be called in which you can interact with the API using
    #   the provided client. The client will be closed after the block returns.
    # @yieldparam client [Adyen::REST::Client] The REST client to use for the session.
    # @return [void]
    # @see Adyen::REST::Client#session
    def self.session(client = self.client, &block)
      client.session(&block)
    end
  end
end
