# encoding: UTF-8

require 'rubygems'
require 'rspec'

gem "activesupport", ">= 3"
require "active_support"
gem "activerecord", ">= 3"
require "active_record"
gem "actionpack", ">= 3"
require "action_view"

$:.unshift File.expand_path('../../lib', __FILE__)

require 'adyen'
require 'adyen/matchers'

RSpec.configure do |config|
  config.include Adyen::Matchers
end
