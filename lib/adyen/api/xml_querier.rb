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

      class NokogiriBackend
        def initialize
          require 'nokogiri'
        end

        def document_for_html(html)
          Nokogiri::HTML::Document.parse(html, nil, 'UTF-8')
        end

        def document_for_xml(xml)
          Nokogiri::XML::Document.parse(xml)
        end

        def perform_xpath(query, root_node)
          root_node.xpath(query, NS)
        end
      end

      class REXMLBackend
        def initialize
          require 'rexml/document'
        end

        def document_for_html(html)
          REXML::Document.new(html)
        end

        def document_for_xml(xml)
          REXML::Document.new(xml)
        end

        def perform_xpath(query, root_node)
          REXML::XPath.match(root_node, query, NS)
        end        
      end

      # @return A backend to handle XML parsing.
      def self.default_backend
        @default_backend ||= begin
          NokogiriBackend.new
        rescue LoadError => e
          REXMLBackend.new
        end
      end

      # Creates an XML querier for an XML document
      def self.xml(data, backend = nil)
        backend ||= default_backend
        self.new(backend.document_for_xml(string_from(data)), backend)
      end

      # Creates an XML querier for an HTML document
      def self.html(data, backend = nil)
        backend ||= default_backend
        self.new(backend.document_for_html(string_from(data)), backend)
      end

      def self.string_from(data)
        if data.is_a?(String)
          data
        elsif data.responds_to?(:body)
          data.body.to_s
        else 
          data.to_s
        end
      end

      attr_reader :backend

      # @param [Nokogiri::XML::NodeSet] data The XML data to wrap.
      def initialize(node, backend)
        @node, @backend = node, backend
      end

      # @param [String] query The xpath query to perform.
      # @yield [XMLQuerier] A new XMLQuerier scoped to the given +query+.
      # @return [XMLQuerier] A new XMLQuerier scoped to the given +query+. Or, if a block is given,
      #                      the result of calling the block.
      def xpath(query)
        result = self.class.new(backend.perform_xpath(query, @node), backend)
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
        @node.map { |n| self.class.new(n, backend) }.map(&block)
      end
    end
  end
end
