# The Adyen module is the container module for all Adyen related functionality,
# which is implemented in submodules. This module only contains some global
# configuration methods.
#
# The most important submodules are:
# * {Adyen::HPP} for interacting with Adyen's Hosted Payment Pages.
# * {Adyen::REST} for communicating with the Adyen REST webservices.
require 'adyen/base'
require 'adyen/version'

require 'adyen/form'
require 'adyen/api'
require 'adyen/rest'
require 'adyen/hpp'

require 'adyen/railtie' if defined?(::Rails) && ::Rails::VERSION::MAJOR >= 3
