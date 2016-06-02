module Adyen

  # Basic exception class for Adyen
  class Error < ::StandardError
  end

  # @return [Configuration] The configuration singleton.
  def self.configuration
    @configuration ||= Adyen::Configuration.new
  end

  def self.configuration=(configuration)
    @configuration = configuration
  end
end

require 'adyen/configuration'
