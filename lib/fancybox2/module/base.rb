require 'logger'
require 'paho-mqtt'

module Fancybox2
  module Module
    class Base
      include Utils

      attr_accessor :logger, :log_level, :log_progname, :mqtt_client

      def initialize(*args)
        options = args.extract_options.deep_symbolize_keys!
        @mqtt_client = options[:mqtt_client]
        @mqtt_client_params = options[:mqtt_client_params] || {}
        @log_level = options[:log_level] || ::Logger::DEBUG
        @log_progname = options[:log_progname] || 'Fancybox2::Module::Base'
        @logger = options[:logger]
      end

      def run
        mqtt_client.connect
      end

      def logger
        return @logger if @logger
        stdout_logger = ::Logger.new STDOUT
        broker_logger = ::Logger.new(Logger::MQTTLogDevice.new(client: mqtt_client), formatter: Logger::JSONFormatter.new)
        @logger = Logger::Multi.new stdout_logger, broker_logger,
                                         level: @log_level,
                                         progname: @log_progname,
                                         escape_data: true
      end

      def mqtt_client
        return @mqtt_client if @mqtt_client
        @mqtt_client = PahoMqtt::Client. new mqtt_params
        @mqtt_client
      end

      private

      def mqtt_default_params
        {
            host:           'localhost',
            port:           1883,
            mqtt_version:   '3.1.1',
            clean_session:  true,
            persistent:     false,
            blocking:       true,
            client_id:      nil,
            username:       nil,
            password:       nil,
            ssl:            false,
            will_topic:     nil,
            will_payload:   nil,
            will_qos:       0,
            will_retain:    false,
            keep_alive:     10,
            ack_timeout:    5
        }
      end

      def mqtt_params
        return @mqtt_params if @mqtt_params
        @mqtt_params = mqtt_default_params.merge(@mqtt_client_params) { |key, old_val, new_val| new_val.nil? ? old_val : new_val }
        @mqtt_params
      end
    end
  end
end