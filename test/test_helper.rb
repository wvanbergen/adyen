# encoding: UTF-8
require 'minitest/autorun'
require 'minitest/pride'
require 'mocha/setup'

require 'adyen'
require 'adyen/matchers'

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
