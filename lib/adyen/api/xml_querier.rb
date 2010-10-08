module Adyen
  module API
    class XMLQuerier
      NS = {
        'soap'      => 'http://schemas.xmlsoap.org/soap/envelope/',
        'payment'   => 'http://payment.services.adyen.com',
        'recurring' => 'http://recurring.services.adyen.com',
        'common'    => 'http://common.services.adyen.com'
      }

      class << self
        attr_accessor :backend

        def backend=(backend)
          @backend = backend
          class_eval do
            private
            if backend == :nokogiri
              def document_for_xml(xml)
                Nokogiri::XML::Document.parse(xml)
              end
              def perform_xpath(query)
                @node.xpath(query, NS)
              end
            else
              def document_for_xml(xml)
                REXML::Document.new(xml)
              end
              def perform_xpath(query)
                REXML::XPath.match(@node, query, NS)
              end
            end
          end
        end
      end

      begin
        require 'nokogiri'
        self.backend = :nokogiri
      rescue LoadError
        require 'rexml/document'
        self.backend = :rexml
      end

      def initialize(data)
        @node = data.is_a?(String) ? document_for_xml(data) : data
      end

      def xpath(query)
        result = self.class.new(perform_xpath(query))
        block_given? ? yield(result) : result
      end

      def text(query)
        xpath("#{query}/text()").to_s.strip
      end

      def children
        @node.first.children
      end

      def empty?
        @node.empty?
      end

      def to_s
        @node.to_s
      end

      def map(&block)
        @node.map { |n| self.class.new(n) }.map(&block)
      end
    end
  end
end
