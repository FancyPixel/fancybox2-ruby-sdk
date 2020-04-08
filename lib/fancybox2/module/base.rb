require 'json'
require 'logger'
require 'paho-mqtt'

module Fancybox2
  module Module
    class Base
      include Config

      attr_accessor :logger, :log_level, :log_progname, :mqtt_client

      def initialize(*args)
        options = args.extract_options.deep_symbolize_keys!
        @mqtt_client = options[:mqtt_client]
        @mqtt_client_params = options[:mqtt_client_params] || {}
        @log_level = options[:log_level] || ::Logger::DEBUG
        @log_progname = options[:log_progname] || 'Fancybox2::Module::Base'
        @logger = options[:logger]
      end

      def default_subscriptions
        [
            "#{name}"
        ]
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

      def name
        fbxfile[:name]
      end

      def mqtt_client
        return @mqtt_client if @mqtt_client
        @mqtt_client = PahoMqtt::Client. new mqtt_params
        @mqtt_client
      end

      def alive
      end

      def start
        # Restart code execution from the beginning
      end

      def stop
        # Stop code excution, but keep broker connection
      end

      def setup
        mqtt_client.connect
      end

      def shutdown
        # Graceful shutdown
        # Do something
        # TODO: signal CORE that I've correctly executed a graceful shutdown (goodbye message)
        # Wait for the receive of a pubcomp (if QoS2) for this message, then...
        mqtt_client.disconnect
        exit 0
      end

      ## MQTT Client callbacks

      def on_client_connect
        # Subscriptions
      end

      def on_client_connack
        # Make default subscriptions
      end

      def on_client_suback
      end

      def on_client_unsuback
      end

      def on_client_puback
      end

      def on_client_pubrel
      end

      def on_client_pubrec
      end

      def on_client_pubcomp
      end

      def on_client_message
      end

      def fbxfile
        return @fbxfile if @fbxfile
        if File.exists? fbxfile_path
          @fbxfile = JSON.parse(File.read(fbxfile_path)).deep_symbolize_keys
        else
          raise Exceptions::FbxfileNotFound.new example_file_path
        end
        @fbxfile
      end

      def fbxfile=(hash_attributes)
        raise ArgumentError, 'You must provide an Hash as argument' unless hash_attributes.is_a?(Hash)
        @fbxfile = hash_attributes.deep_symbolize_keys
      end

      def fbxfile_path
        # Tell if this is the Base class or an instance of a subclass
        ancestors = self.class.ancestors[1..-1] # Exclude self from ancestors
        if ancestors.include? Base
          # I'm a subclass so Fbxfile.example should be in a precise location
          Config::FBXFILE_DEFAULT_FILE_PATH
        else
          # I'm the Base class, use Fbxfile.example
          "#{__dir__}/config/Fbxfile.example"
        end
      end

      def fbxfile_path=(path)
        @fbxfile_path = path
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
            ack_timeout:    5,
            on_connack:     on_client_connack,
            on_suback:      on_client_suback,
            on_unsuback:    on_client_unsuback,
            on_puback:      on_client_puback,
            on_pubrel:      on_client_pubrel,
            on_pubrec:      on_client_pubrec,
            on_pubcomp:     on_client_pubcomp,
            on_message:     on_client_message
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