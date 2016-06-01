# encoding: UTF-8
require 'minitest/autorun'
require 'minitest/pride'
require 'mocha/setup'

require 'adyen/base'
require 'adyen/matchers'

require 'helpers/configure_adyen'
require 'helpers/test_cards'

require 'pp'

module Adyen::Test
  module Flaky
    def flaky_test(name, &block)
      define_method("test_#{name}") do
        attempt = 0
        test_instance = self
        begin
          attempt += 1
          test_instance.instance_eval(&block)
        rescue Minitest::Assertion
          attempt < 3 ? retry : raise
        end
      end
    end
  end

  module EachXMLBackend
    XML_BACKENDS = [Adyen::API::XMLQuerier::NokogiriBackend, Adyen::API::XMLQuerier::REXMLBackend]

    def for_each_xml_backend(&block)
      XML_BACKENDS.each do |xml_backend|
        begin
          Adyen::API::XMLQuerier.stubs(:default_backend).returns(xml_backend.new)
          block.call(xml_backend)
        ensure
          Adyen::API::XMLQuerier.unstub(:default_backend)
        end
      end
    end
  end
end
