require 'spec_helper'

require 'rubygems'
require 'spec'
require 'spec/autorun'

gem 'activesupport', '2.3.9'
gem 'activerecord', '2.3.9'
gem 'actionpack', '2.3.9'
require 'active_support'

$:.unshift File.expand_path('../../lib', __FILE__)

require 'adyen'
require 'adyen/matchers'

Spec::Runner.configure do |config|
  config.include Adyen::Matchers
end
