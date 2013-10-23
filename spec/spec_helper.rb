# encoding: UTF-8

require 'rubygems'
require 'rspec'

require 'adyen'
require 'spec/matchers'

RSpec.configure do |config|
  config.include Adyen::Matchers
end

# Load support files
Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].each { |f| require f }
