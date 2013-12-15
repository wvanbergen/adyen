module Adyen
  module API
    # A simple wrapper around the raw response body returned by Adyen. It abstracts away the
    # differences between REXML and Nokogiri, ensuring that this library will always work.
    #
    # At load time, it will first check if Nokogiri is available, otherwise REXML is used. This
    # means that if you want to use Nokogiri and have it installed as a gem, you will have to make
    # sure rubygems is loaded and the gem has been activated. Or assign the backend to use.
    class XMLQuerier
      # The namespaces used by Adyen.
      NS = {
        'soap'      => 'http://schemas.xmlsoap.org/soap/envelope/',
        'payment'   => 'http://payment.services.adyen.com',
        'recurring' => 'http://recurring.services.adyen.com',
        'common'    => 'http://common.services.adyen.com'
      }

      class << self
        # @return [:rexml, :nokogiri] The XML backend to use.
        attr_reader :backend
        def backend=(backend)
          @backend = backend
          class_eval do
            private
            if backend == :nokogiri
              def document_for_xml(xml)
                Nokogiri::XML::Document.parse(xml, nil, 'UTF-8')
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

      # @param [String, Array, Nokogiri::XML::NodeSet] data The XML data to wrap.
      def initialize(data)
        @node = data.is_a?(String) ? document_for_xml(data) : data
      end

      # @param [String] query The xpath query to perform.
      # @yield [XMLQuerier] A new XMLQuerier scoped to the given +query+.
      # @return [XMLQuerier] A new XMLQuerier scoped to the given +query+. Or, if a block is given,
      #                      the result of calling the block.
      def xpath(query)
        result = self.class.new(perform_xpath(query))
        block_given? ? yield(result) : result
      end

      # @param [String] query The xpath query to perform.
      # @return [String] The contents of the text node indicated by the given +query+.
      def text(query)
        xpath("#{query}/text()").to_s.strip
      end

      # @return [Array, Nokogiri::XML::NodeSet] The children of this node.
      def children
        @node.first.children
      end

      # @return [Boolean] Returns whether or not this node is empty.
      def empty?
        @node.empty?
      end

      # @return [String] A string representation of this node.
      def to_s
        Array === @node ? @node.join("") : @node.to_s
      end

      # @yield [XMLQuerier] A member of this node set, ready to be queried.
      # @return [Array] The list of nodes wrapped in XMLQuerier instances.
      def map(&block)
        @node.map { |n| self.class.new(n) }.map(&block)
      end
    end
  end
end
