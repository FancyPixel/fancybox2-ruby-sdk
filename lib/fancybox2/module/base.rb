require 'json'
require 'logger'
require 'paho-mqtt'

module Fancybox2
  module Module
    class Base

      attr_accessor :logger, :log_level, :log_progname, :mqtt_client, :mqtt_client_params

      def initialize(*args)
        options = args.extract_options.deep_symbolize_keys!
        if options[:mqtt_client]
          self.mqtt_client = options[:mqtt_client]
        end
        @mqtt_client_params = options[:mqtt_client_params] || {}
        @log_level = options[:log_level] || ::Logger::DEBUG
        @log_progname = options.fetch(:log_progname, 'Fancybox2::Module::Base')
        @logger = options[:logger]
      end

      def alive
      end

      def core_command(n)
      end
      
      def default_topics
        [
            Config::DEFAULT_TOPIC_FORMAT % [name, 'start'],
            Config::DEFAULT_TOPIC_FORMAT % [name, 'stop'],
            Config::DEFAULT_TOPIC_FORMAT % [name, 'restart'],
            Config::DEFAULT_TOPIC_FORMAT % [name, 'shutdown'],
            Config::DEFAULT_TOPIC_FORMAT % [name, 'logger']
        ]

      end

      def fbxfile
        return @fbxfile if @fbxfile
        if File.exists? fbxfile_path
          @fbxfile = JSON.parse(File.read(fbxfile_path)).deep_symbolize_keys
        else
          raise Exceptions::FbxfileNotFound.new Config::FBXFILE_DEFAULT_FILE_PATH
        end
        @fbxfile
      end

      def fbxfile=(hash_attributes)
        raise ArgumentError, 'You must provide an Hash as argument' unless hash_attributes.is_a?(Hash)
        @fbxfile = hash_attributes.deep_symbolize_keys
      end

      def fbxfile_path
        return @fbxfile_path if @fbxfile_path
        # Tell if this is the Base class or an instance of a subclass
        ancestors = self.class.ancestors[1..-1] # Exclude self from ancestors
        if ancestors.include? Base
          # I'm a subclass so Fbxfile should be in a precise location
          @fbxfile_path = Config::FBXFILE_DEFAULT_FILE_PATH
        else
          # I'm the Base class, use Fbxfile.example
          @fbxfile_path = Config::FBXFILE_EXAMPLE_FILE_PATH
        end
        @fbxfile_path
      end

      def fbxfile_path=(path)
        @fbxfile_path = path
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

      def mqtt_client=(client)
        unless client.is_a? PahoMqtt::Client
          raise Exceptions::NotValidMQTTClient.new
        end
        @mqtt_client = client
      end

      def name
        fbxfile[:name]
      end

      def restart
        # Stop + start
      end

      def shutdown
        # Graceful shutdown
        # Do something
        # TODO: signal CORE that I've correctly executed a graceful shutdown (goodbye message)
        # Wait for the receive of a pubcomp (if QoS2) for this message, then...
        mqtt_client.disconnect
        exit 0
      end

      def start
        # Start code execution from scratch
        puts "START"
      end

      def setup
        mqtt_client.connect
      end

      def stop
        # Stop code excution, but keep broker connection
      end

      ## MQTT Client callbacks

      def on_client_connack
        # Setup default callbacks
        default_topics.each do |topic|
          unless topic.is_a? String
            raise Exceptions::NotAValidSubscription.new topic
          end
          pieces = topic.split "/#{name}/"
          action = pieces.last
          unless action
            raise Exceptions::NotAValidSubscription.new topic
          end
          if respond_to? action
            mqtt_client.add_topic_callback topic do |packet|
              if method(action).arity.abs > 0
                send action, packet
              else
                send action
              end
            end
          else
            logger.warn "Handler not defined for default subscription #{topic}. Messages received on this topic will not be handled"
          end
        end

        # Subscribe to all messages directed to me
        mqtt_client.subscribe [Config::DEFAULT_TOPIC_FORMAT % [name, '#'], 2]
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

      private

      def mqtt_default_params
        {
            host:           'localhost',
            port:           1883,
            mqtt_version:   '3.1.1',
            clean_session:  true,
            persistent:     true,
            blocking:       false,
            client_id:      nil,
            username:       nil,
            password:       nil,
            ssl:            false,
            will_topic:     nil,
            will_payload:   nil,
            will_qos:       0,
            will_retain:    false,
            keep_alive:     7,
            ack_timeout:    5,
            on_connack:     proc { on_client_connack },
            on_suback:      proc { on_client_suback },
            on_unsuback:    proc { on_client_unsuback },
            on_puback:      proc { on_client_puback },
            on_pubrel:      proc { on_client_pubrel },
            on_pubrec:      proc { on_client_pubrec },
            on_pubcomp:     proc { on_client_pubcomp },
            on_message:     proc { on_client_message }
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