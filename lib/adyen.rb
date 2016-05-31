# The Adyen module is the container module for all Adyen related functionality,
# which is implemented in submodules. This module only contains some global
# configuration methods.
#
# The most important submodules are:
# * {Adyen::HPP} for interacting with Adyen's Hosted Payment Pages.
# * {Adyen::REST} for communicating with the Adyen REST webservices.
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

require 'adyen/version'
require 'adyen/configuration'
require 'adyen/util'
require 'adyen/hpp'
require 'adyen/rest/signature'
require 'adyen/form'
require 'adyen/api'
require 'adyen/rest'
require 'adyen/signature'

require 'adyen/railtie' if defined?(::Rails) && ::Rails::VERSION::MAJOR >= 3
