class Adyen::Configuration

  def initialize
    self.default_api_params = {}
  end

  # The Rails environment for which to use to Adyen "live" environment.
  LIVE_RAILS_ENVIRONMENTS = ['production']

  # Setter voor the current Adyen environment.
  # @param ['test', 'live'] env The Adyen environment to use
  def environment=(env)
    @environment = env
  end

  # Returns the current Adyen environment, either test or live.
  #
  # It will return the +override+ value if set, it will return the value set
  # using {Adyen.configuration.environment=} otherwise. If this value also isn't set, the
  # environment is determined with {Adyen.autodetect_environment}.
  #
  # @param ['test', 'live'] override An environment to override the default with.
  # @return ['test', 'live'] The Adyen environment that is currently being used.
  def environment(override = nil)
    override || @environment || autodetect_environment
  end

  # Autodetects the Adyen environment based on the RAILS_ENV constant.
  # @return ['test', 'live'] The Adyen environment that corresponds to the Rails environment
  def autodetect_environment
    rails_env = if defined?(::Rails) && ::Rails.respond_to?(:env)
      ::Rails.env.to_s
    elsif defined?(::RAILS_ENV)
      ::RAILS_ENV.to_s
    end
    
    LIVE_RAILS_ENVIRONMENTS.include?(rails_env) ? 'live' : 'test'
  end

  # The username that’s used to authenticate for the Adyen SOAP services. It should look
  # something like ‘+ws@AndyInc.SuperShop+’
  #
  # @return [String]
  attr_accessor :api_username

  # The password that’s used to authenticate for the Adyen SOAP services. You can configure it
  # in the user management tool of the merchant area.
  #
  # @return [String]
  attr_accessor :api_password

  # Default arguments that will be used for every API call. You can override these default
  # values by passing a diffferent value to the service class’s constructor.
  #
  # @example
  #   Adyen::API.default_soap_params[:merchant_account] = 'SuperShop'
  #
  # @return [Hash]
  attr_accessor :default_api_params
end
