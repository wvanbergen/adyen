require 'adyen/rest/client'

module Adyen

  # The Adyen::REST module allows you to interact with Adyen's REST API.
  #
  # The primary method here is {Adyen::REST.session}, which will yield a
  # {Adyen::REST::Client} which you can use to send API requests.
  #
  # @example
  #
  #     Adyen::REST.session do |client|
  #       client.http.read_timeout = 5
  #       response = client.api_request(...)
  #       # ...
  #     end
  #
  # @see Adyen::REST.session Use Adyen::REST.session to run code against the API.
  # @see Adyen::REST::Client Adyen::REST::Client implements the actual API calls.
  module REST

    # Provides a REST API client this is configured using the values in <tt>Adyen.configuration</tt>.
    # @param options [Hash] (see Adyen::REST::Client#initialize)
    # @return [Adyen::REST::Client] A configured client instance
    # @see .session
    def self.client
      Adyen::REST::Client.new(
        Adyen.configuration.environment,
        Adyen.configuration.api_username,
        Adyen.configuration.api_password
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
    # @see Adyen::REST::Client
    def self.session(client = nil)
      client ||= self.client
      yield(client)
    ensure
      client.close
    end
  end
end
