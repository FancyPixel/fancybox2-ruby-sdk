# frozen_string_literal: true

module Fancybox2
  module Logger
    class MQTTLogDevice

      attr_accessor :client, :topic

      def initialize(topic, *args)
        @topic = topic
        options = args.extract_options.deep_symbolize_keys
        @client = options[:client]
        unless @client.respond_to?(:publish)
          raise ArgumentError, "provided client does not respond to 'publish'"
        end
        unless @client.respond_to?(:connected?)
          raise ArgumentError, "provided client does not respond to 'connected?'"
        end
      end

      def write(message)
        if @client && @client.connected?
          @client.publish @topic, message
        end
      end

      def close(*args)
        # Do nothing.
        # Future: close only if client is internal
      end
    end
  end
end
