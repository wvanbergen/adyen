# The Adyen module is the container module for all Adyen related functionality, 
# which is implemented in submodules. This module only contains some global 
# configuration methods.
#
# The most important submodules are:
# * {Adyen::Form} for generating payment form fields, generating redirect URLs 
#   to the Adyen payment system, and generating and checking of signatures.
# * {Adyen::Notification} for handling notifications sent by Adyen to your servers.
# * {Adyen::SOAP} for communicating with the Adyen SOAP services for payment
#   maintenance and issuing recurring payments.
module Adyen

  # Version constant for the Adyen plugin.
  # DO NOT CHANGE THIS VALUE BY HAND. It will be updated automatically by
  # the gem:release rake task.
  VERSION = "0.3.7"

  # Loads configuration settings from a Hash.
  #
  # @param [Hash] hash The (nested Hash) with configuration variables.
  # @param [Module] mod The current working module. This parameter is used
  #    to recursively traverse the hash for submodules.
  # @raise [StandardError] An exception is raised of an unkown configuration 
  #    setting is encountered in the hash.
  def self.load_config(hash, mod = Adyen)
    hash.each do |key, value|
      if key.to_s =~ /^[a-z]/ && mod.respond_to?(:"#{key}=")
        mod.send(:"#{key}=", value)
      elsif key.to_s =~ /^[A-Z]/
        self.load_config(value, mod.const_get(key))
      else
        raise "Unknown configuration variable: '#{key}' for #{mod}"
      end
    end
  end

  # The Rails environment for which to use to Adyen "live" environment.
  LIVE_RAILS_ENVIRONMENTS = ['production']

  # Setter voor the current Adyen environment.
  # @param ['test', 'live'] env The Adyen environment to use
  def self.environment=(env)
    @environment = env
  end

  # Returns the current Adyen environment, either test or live.
  #
  # It will return the +override+ value if set, it will return the value set
  # using {Adyen.environment=} otherwise. If this value also isn't set, the
  # environemtn is determined with {Adyen.autodetect_environment}.
  #
  # @param ['test', 'live'] override An environemt to override the default with.
  # @return ['test', 'live'] The Adyen environment that is currently being used.
  def self.environment(override = nil)
    override || @environment || Adyen.autodetect_environment
  end

  # Autodetects the Adyen environment based on the RAILS_ENV constant.
  # @return ['test', 'live'] The Adyen environment that corresponds to the Rails environment
  def self.autodetect_environment
    (defined?(RAILS_ENV) && Adyen::LIVE_RAILS_ENVIRONMENTS.include?(RAILS_ENV.to_s.downcase)) ? 'live' : 'test'
  end

  # Loads submodules on demand, so that dependencies are not required.
  # @param [Symbol] sym The name of the submodule
  # @return [Module] The actual loaded submodule.
  # @raise [LoadError, NameError] If the submodule cannot be loaded
  def self.const_missing(sym)
    require "adyen/#{sym.to_s.downcase}"
    return Adyen.const_get(sym)
  rescue Exception
    super(sym)
  end
end

require 'adyen/encoding'
require 'adyen/formatter'
