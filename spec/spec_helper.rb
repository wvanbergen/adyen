$: << File.join(File.dirname(__FILE__), '..', 'lib')

require 'rubygems'
require 'spec'
require 'spec/autorun'
require 'active_support'

require 'adyen'

Spec::Runner.configure do |config|
  config.include Adyen::Matchers
end
