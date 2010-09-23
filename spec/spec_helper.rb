require 'spec_helper'

require 'rubygems'
require 'spec'
require 'spec/autorun'
require 'active_support'

require 'adyen'
require 'adyen/matchers'

Spec::Runner.configure do |config|
  config.include Adyen::Matchers
end
