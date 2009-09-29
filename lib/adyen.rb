module Adyen
  LIVE_RAILS_ENVIRONMENTS = ['production']

  # Setter voor the current Adyen environment.
  # Must be either 'test' or 'live'
  def self.environment=(env)
    @environment = env
  end

  # Returns the current Adyen environment.
  # Returns either 'test' or 'live'.
  def self.environment(override = nil)
    override || @environment || Adyen.autodetect_environment
  end

  # Autodetects the Adyen environment based on the RAILS_ENV constant
  def self.autodetect_environment
    (defined?(RAILS_ENV) && Adyen::LIVE_RAILS_ENVIRONMENTS.include?(RAILS_ENV.to_s.downcase)) ? 'live' : 'test'
  end

  # Loads submodules on demand, so that dependencies are not required.
  def self.const_missing(sym)
    require "adyen/#{sym.to_s.downcase}"
    return Adyen.const_get(sym)
  rescue
    super(sym)
  end
end

require 'adyen/encoding'
require 'adyen/formatter'
