# encoding: UTF-8

require 'rubygems'
require 'rspec'

$:.unshift File.expand_path('../../lib', __FILE__)

require 'adyen'
require 'adyen/matchers'

RSpec.configure do |config|
  config.include Adyen::Matchers
end
