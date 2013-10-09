module Adyen
  class Engine < ::Rails::Engine
    isolate_namespace Adyen
  end

  class ConfigContainer
    alias_method :orig_method_missing, :method_missing

    def configure_with(&block)
      raise ConfigMissing.new unless block
      extend EngineConfiguration
      class << self; alias_method :method_missing, :orig_method_missing; end

      yield self
      # set defaults if they haven't already been set
      @disable_basic_auth ||= false
      @payment_result_redirect_block ||= lambda {|c| c.payments_complete_path()}
    end

    def method_missing(method, *args)
      raise NotConfigured.new method
    end
  end

  module EngineConfiguration
    attr_accessor :http_username, :http_password, :disable_basic_auth

    def redirect_payment_with(&block)
      @payment_result_redirect_block = lambda {|c| block.call(c) }
    end

    def payment_result_redirect(controller)
      @payment_result_redirect_block.call(controller)
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
    def initialize(method_name)
      super "You have not configured the Adyen engine so cannot call #{method_name}.  Please add an Adyen#setup block into your environments/#{Rails.env}.rb file."
    end
  end

  def self.setup(&block)
    @config ||= ConfigContainer.new
    @config.configure_with &block
  end

  def self.config
    @config ||= ConfigContainer.new
  end

  Adyen::Configuration.class_eval do
    def engine
      Adyen.config
    end
  end
end
