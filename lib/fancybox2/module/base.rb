require 'json'
require 'logger'
require 'paho-mqtt'
require 'concurrent-ruby'

module Fancybox2
  module Module
    class Base

      attr_reader :logger, :mqtt_client, :fbxfile, :fbxfile_path

      def initialize(*args)
        options = args.extract_options.deep_symbolize_keys!
        @internal_mqtt_client = false

        @fbxfile_path = options.fetch :fbxfile_path, Config::FBXFILE_DEFAULT_FILE_PATH
        @fbxfile = check_and_return_fbxfile options.fetch(:fbxfile, load_fbx_file)
        @mqtt_client_params = options[:mqtt_client_params] || {}
        @mqtt_client = options[:mqtt_client] || build_mqtt_client
        @log_level = options.fetch :log_level, ::Logger::INFO
        @log_progname = options.fetch :log_progname, 'Fancybox2::Module::Base'
        @logger = options.fetch :logger, create_default_logger
        @status = :stopped
        @alive_task = nil
      end
      
      def default_actions
        {
            start:    proc { |packet| start packet },
            stop:     proc { stop },
            restart:  proc { |packet| restart packet },
            shutdown: proc { shutdown },
            logger:   proc { |packet| action_logger packet }
        }
      end

      def message_to(dest, action = '', payload = nil, retain = false, qos = 2)
        topic = topic_for dest: dest, action: action
        payload = case payload
                  when Hash, Array
                    payload.to_json
                  else
                    payload
                  end
        logger.debug "#{self.class}#message_to '#{topic}' payload: #{payload}"
        mqtt_client.publish topic, payload, retain, qos
      end

      def name
        fbxfile[:name]
      end

      def on_action(action, callback = nil, &block)
        topic = topic_for action: action
        mqtt_client.add_topic_callback topic do |packet|
          payload = packet.payload
          # Try to parse payload as JSON. Rescue with original payload in case of error
          packet.payload = JSON.parse(payload) rescue payload
          if block_given?
            block.call packet
          elsif callback && callback.is_a?(Proc)
            callback.call packet
          end
        end
      end

      def remove_action(action)
        topic = topic_for action: action
        mqtt_client.remove_topic_callback topic
      end

      def restart(packet)
        # Stop + start
        stop
        start packet
      end

      def send_alive(interval: 5000)
        # Interval is expected to be msec, so convert it to secs
        interval /= 1000
        @alive_task.shutdown if @alive_task
        @alive_task = Concurrent::TimerTask.new(execution_interval: interval, timeout_interval: 2, run_now: true) do
          message_to :core, :alive, {
              status: @status,
              lastSeen: Time.now.utc
          }
        end
        @alive_task.execute
      end

      def setup
        unless @setted_up
          begin
            logger.debug 'Connecting to the broker...'
            mqtt_client.connect
          rescue PahoMqtt::Exception => e
            logger.error "Error while connecting to the broker: #{e.message}"
            retry
          end

          # task = Concurrent::TimerTask.new{ puts 'Boom!' }
          @setted_up = true
        end
      end

      def shutdown
        logger.debug "Received 'shutdown'"
        # Graceful shutdown
        # Do something
        # TODO: signal CORE that I've correctly executed a graceful shutdown (goodbye message)
        # Wait for the receive of a pubrec for this message, then...
        @alive_task.shutdown
        mqtt_client.disconnect
        exit 0
      end

      def start(packet)
        configs = packet.payload
        # Start code execution from scratch
        logger.debug "Received 'start'"
        @status = :started
        send_alive interval: configs['aliveTimeout']
      end

      def stop
        @status = :stopped
        # Stop code excution, but keep broker connection and continue to send alive
      end

      def topic_for(dest: nil, action: nil)
        dest = dest.to_s
        action = action.to_s
        # Tell if the topic is "for the Core" or "for some other module"
        core_string = ''
        module_name = self.name
        case dest
        when 'core'
          core_string = 'core/'
        end

        Config::DEFAULT_TOPIC_FORMAT % [core_string, module_name, action]
      end

      ## MQTT Client callbacks

      def on_client_connack
        logger.debug 'Connected to the broker'
        # Setup default callbacks
        default_actions.each do |action_name, callback|
          action_name = action_name.to_s

          on_action action_name do |packet|
            if callback.is_a? Proc
              callback.call packet
            else
              logger.warn "No valid callback defined for '#{action_name}'"
            end
          end
        end

        # Subscribe to all messages directed to me
        logger.debug 'Making broker subscriptions'
        mqtt_client.subscribe [topic_for(action: '#'), 2]
      end

      def on_client_suback
        # Client subscribed, we're ready to rock -> Tell core
        logger.debug 'Subscriptions done'
        logger.debug "Sending 'ready' to core"
        message_to :core, :ready
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

      def build_mqtt_client
        @internal_mqtt_client = true
        PahoMqtt::Client.new mqtt_params
      end

      def check_and_return_fbxfile(hash_attributes)
        raise ArgumentError, 'You must provide an Hash as argument' unless hash_attributes.is_a?(Hash)
        hash_attributes.deep_symbolize_keys
      end

      def create_default_logger
        stdout_logger = ::Logger.new STDOUT
        broker_logger = ::Logger.new(Logger::MQTTLogDevice.new(topic_for(dest: :core, action: :logs),
                                                               client: mqtt_client),
                                     formatter: Logger::JSONFormatter.new)
        logger = Logger::Multi.new stdout_logger, broker_logger,
                                    level: @log_level,
                                    progname: @log_progname
        logger
      end

      def load_fbx_file
        if File.exists? @fbxfile_path
          @fbxfile = JSON.parse(File.read(@fbxfile_path)).deep_symbolize_keys
        else
          raise Exceptions::FbxfileNotFound.new @fbxfile_path
        end
      end

      def mqtt_default_params
        {
            host:             'localhost',
            port:             1883,
            mqtt_version:     '3.1.1',
            clean_session:    true,
            persistent:       true,
            blocking:         false,
            reconnect_limit:  -1,
            reconnect_delay:  1,
            client_id:        nil,
            username:         nil,
            password:         nil,
            ssl:              false,
            will_topic:       nil,
            will_payload:     nil,
            will_qos:         0,
            will_retain:      false,
            keep_alive:       7,
            ack_timeout:      5,
            on_connack:       proc { on_client_connack },
            on_suback:        proc { on_client_suback },
            on_unsuback:      proc { on_client_unsuback },
            on_puback:        proc { on_client_puback },
            on_pubrel:        proc { on_client_pubrel },
            on_pubrec:        proc { on_client_pubrec },
            on_pubcomp:       proc { on_client_pubcomp },
            on_message:       proc { on_client_message }
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