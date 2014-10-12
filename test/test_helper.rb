# encoding: UTF-8
require 'minitest/autorun'
require 'minitest/pride'
require 'mocha/setup'

require 'adyen'
require 'adyen/matchers'

require 'helpers/test_server'
require 'helpers/test_cards'

require 'pp'

module Adyen::Test
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

def setup_api_configuration
  Adyen.configuration.default_api_params = { :merchant_account => 'VanBergenORG' }
  Adyen.configuration.api_username = 'ws@Company.VanBergen'
  Adyen.configuration.api_password = '7phtHzbfnzsp'
end
