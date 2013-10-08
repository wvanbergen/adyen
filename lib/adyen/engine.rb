module Adyen
  class Engine < ::Rails::Engine
    isolate_namespace Adyen
  end

  class FailureConfig
    def method_missing(method, *args)
      raise NotConfigured.new
    end
  end

  # Used to interpret the config run against the engine, and prevents on the fly
  # reconfiguration of things that should not be reconfigured (well, okay, doesn't
  # prevent, but makes it a bit less likely to happen accidentally)
  class EngineConfiguration
    attr_accessor :http_username, :http_password, :disable_basic_auth

    def redirect_payment_with(&block)
      @payment_result_redirect_block = lambda {|c| block.call(c) }
    end

    def payment_result_redirect(controller)
      @payment_result_redirect_block.call(controller)
    end

    def initialize(&block)
      @skins ||= {}
      raise ConfigMissing.new unless block
      yield self
      # set defaults if they haven't already been set
      @disable_basic_auth ||= false
      @payment_result_redirect_block ||= lambda {|c| c.payments_complete_path()}
    end

    def add_main_skin(skin_code, secret)
      Adyen.configuration.register_form_skin(:main, skin_code, secret)
    end

    def method_missing method, *args
      Rails.logger.error "Your Adyen configuration is incorrect.  There is no setting called #{method}"
      super
    end
  end

  class ConfigMissing < StandardError
    def initialize
      super 'You have not passed a block to the Adyen#setup method!'
    end
  end

  class NotConfigured < StandardError
    def initialize
      super "You have not configured the Adyen engine.  Please add an Adyen#setup block into your enovironments/#{Rails.env}.rb file."
    end
  end

  def self.setup(&block)
    @config = EngineConfiguration.new &block
  end

  def self.config
    @config ||= FailureConfig.new
  end
end
