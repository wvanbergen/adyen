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

  # Used to interpret the config run against the engine, and prevents on the fly
  # reconfiguration of things that should not be reconfigured
  class Configurator
    attr_accessor :http_username, :http_password

    def initialize(&block)
      raise ConfigMissing.new unless block
      yield self
    end
  end

  class ConfigMissing < Exception
    def message
      'You have not passed a block to the Adyen#setup method!'
    end
  end

  def self.setup(&block)
    config = Configurator.new &block
    @config = EngineConfiguration.new(config.http_username, config.http_password)
  end

  def self.config
    @config
  end
end
