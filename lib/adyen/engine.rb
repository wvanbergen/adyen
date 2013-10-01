module Adyen
  class Engine < ::Rails::Engine
    isolate_namespace Adyen
  end

  class EngineConfiguration
    attr_reader :http_username, :http_password, :disable_basic_auth

    def initialize(http_username, http_password, configurator)
      @http_username = http_username
      @http_password = http_password
      @disable_basic_auth = configurator.disable_basic_auth
    end
  end

  class FailureConfig
    def method_missing method, *args
      raise NotConfigured.new
    end
  end

  # Used to interpret the config run against the engine, and prevents on the fly
  # reconfiguration of things that should not be reconfigured
  class Configurator
    attr_accessor :http_username, :http_password, :disable_basic_auth

    def initialize(&block)
      @disable_basic_auth = false
      raise ConfigMissing.new unless block
      yield self
    end
  end

  class ConfigMissing < Exception
    def initialize
      super 'You have not passed a block to the Adyen#setup method!'
    end
  end

  class NotConfigured < Exception
    def initialize
      super "You have not configured the Adyen engine.  Please add an Adyen#setup block into your enovironments/#{Rails.env}.rb file."
    end
  end

  def self.setup(&block)
    config = Configurator.new &block
    @config = EngineConfiguration.new(config.http_username, config.http_password, config)
  end

  def self.config
    @config ||= FailureConfig.new
  end
end
