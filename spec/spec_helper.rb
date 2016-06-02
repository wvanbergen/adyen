# encoding: UTF-8

require 'rspec'
require 'adyen/matchers'

RSpec.configure do |config|
  config.include Adyen::Matchers
end
