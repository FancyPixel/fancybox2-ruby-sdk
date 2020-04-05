module Fancybox2
  module Logger
    class MQTTLogDevice
      DEFAULT_TOPIC = '/log'

      attr_accessor :client, :topic

      def initialize(*args)
        options = args.extract_options.deep_symbolize_keys
        @client = options[:client]
        unless @client.respond_to?(:publish)
          raise ArgumentError, "provided client does not respond to 'publish'"
        end
        @topic = options[:topic] || DEFAULT_TOPIC
      end

      def write(message)
        @client.publish @topic, message
      end

      def close(*args)
        # Do nothing.
        # Future: close only if client is internal
      end
    end
  end
end
