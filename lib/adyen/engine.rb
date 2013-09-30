module Adyen
  class Engine < ::Rails::Engine
    isolate_namespace Adyen
  end

  class EngineConfiguration
    attr_reader :http_username, :http_password

    def initialize(http_username, http_password)
      @http_username = http_username
      @http_password = http_password
    end
  end

  class Configurator
    attr_accessor :http_username, :http_password
  end

  def self.setup &block

    config = Configurator.new

    yield config

    @config = EngineConfiguration.new(config.http_username, config.http_password)
  end

  def self.config
    @config
  end
end
