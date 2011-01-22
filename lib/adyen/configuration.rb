class Adyen::Configuration

  def initialize
    @default_api_params  = {}
    @default_form_params = {}
    @form_skins          = {}
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
  # using Adyen.configuration.environment= otherwise. If this value also isn't set, the
  # environment is determined with autodetect_environment.
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
  #   Adyen.configuration.default_api_params[:merchant_account] = 'SuperShop'
  #
  # @return [Hash]
  attr_accessor :default_api_params

  # Default arguments that will be used for in every HTML form.
  #
  # @example
  #   Adyen.configuration.default_form_params[:shared_secret] = 'secret'
  #
  # @return [Hash]
  attr_accessor :default_form_params

  ######################################################
  # SKINS
  ######################################################

  # Returns all registered skins and their accompanying skin code and shared secret.
  #
  # @return [Hash] The hash of registered skins.
  attr_reader :form_skins
  
  # Sets the registered skins.
  #
  # @param [Hash<Symbol, Hash>] hash A hash with the skin name as key and the skin parameter hash 
  #    (which should include +:skin_code+ and +:shared_secret+) as value.
  #
  # @see Adyen::Configuration.register_form_skin
  def form_skins=(hash)
    @form_skins = hash.inject({}) do |skins, (name, skin)|
      skins[name.to_sym] = skin.merge(:name => name.to_sym)
      skins
    end
  end

  # Registers a skin for later use.
  #
  # You can store a skin using a self defined symbol. Once the skin is registered,
  # you can refer to it using this symbol instead of the hard-to-remember skin code.
  # Moreover, the skin's shared_secret will be looked up automatically for calculting
  # signatures.
  #
  # @example
  #   Adyen::Configuration.register_form_skin(:my_skin, 'dsfH67PO', 'Dfs*7uUln9')
  #
  # @param [Symbol] name The name of the skin.
  # @param [String] skin_code The skin code for this skin, as defined by Adyen.
  # @param [String] shared_secret The shared secret used for signature calculation.
  def register_form_skin(name, skin_code, shared_secret)
    @form_skins[name.to_sym] = { :name => name.to_sym, :skin_code => skin_code, :shared_secret => shared_secret }
  end

  # Returns a skin information by name.
  #
  # @param [Symbol] skin_name The name of the skin
  # @return [Hash, nil] A hash with the skin information, or nil if not found.
  def form_skin_by_name(skin_name)
    @form_skins[skin_name.to_sym]
  end

  # Returns skin information by code code.
  #
  # @param [String] skin_code The code of the skin.
  #
  # @return [Hash, nil] A hash with the skin information, or nil if not found.
  def form_skin_by_code(skin_code)
    if skin = @form_skins.detect { |(name, skin)| skin[:skin_code] == skin_code }
      skin.last
    end
  end

  # Returns the shared secret belonging to a skin.
  #
  # @param [String] skin_code The skin code of the skin
  #
  # @return [String, nil] The shared secret for the skin, or nil if not found.
  def form_skin_shared_secret_by_code(skin_code)
    if skin = form_skin_by_code(skin_code)
      skin[:shared_secret]
    end
  end
end
