$: << File.join(File.dirname(__FILE__), '..', 'lib')

require 'rubygems'
require 'spec'

require 'adyen'
require 'adyen/matchers'

Spec::Runner.configure do |config|
  config.include Adyen::Matchers
end
