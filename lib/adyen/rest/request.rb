module Adyen
  module REST
    class Request
      attr_accessor :action, :attributes, :options

      def initialize(action, attributes, options = {})
        @action, @attributes, @options = action, attributes, options
      end

      def prefix
        @prefix ||= options[:prefix].to_s
      end

      def flattened_attributes
        if prefix
          Adyen::Util.flatten(prefix => attributes, :action => action)
        else
          Adyen::Util.flatten(attributes.merge(:action => action))
        end
      end
    end
  end
end
