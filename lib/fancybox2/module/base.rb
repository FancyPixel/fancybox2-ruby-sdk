require 'json'
require 'yaml'
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

      def message_to(dest, action = '', payload = '', retain = false, qos = 2)
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
        topic = topic_for source: :core, action: action
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

      def on_logger(packet = nil, &block)
        if block_given?
          @on_logger = block
          return
        end
        @on_logger.call(packet) if @on_logger
        configs = packet.payload
        logger.level = configs['level'] if configs['level']
      end

      def on_logger=(callback)
        @on_logger = callback if callback.is_a?(Proc)
      end

      def on_restart(packet = nil, &block)
        if block_given?
          @on_restart = block
          return
        end
        @on_restart.call(packet) if @on_restart
        # Stop + start
        on_stop
        on_start packet
      end

      def on_restart=(callback)
        @on_restart = callback if callback.is_a?(Proc)
      end

      def on_shutdown(do_exit = true, &block)
        if block_given?
          @on_shutdown = block
          return
        end

        shutdown_ok = true
        logger.debug "Received 'shutdown' command"
        # Stop sending alive messages
        @alive_task.shutdown if @alive_task

        begin
          # Call user code if any
          @on_shutdown.call if @on_shutdown
        rescue StandardError => e
          logger.error "Error during shutdown: #{e.message}"
          shutdown_ok = false
        end

        # Signal core that we've executed shutdown operations.
        # This message is not mandatory, so keep it simple
        shutdown_message = shutdown_ok ? 'ok' : 'nok'
        logger.debug "Sending shutdown message to core with status '#{shutdown_message}'"
        message_to :core, :shutdown, { status: shutdown_message }
        sleep 0.05 # Wait some time in order to be sure that the message has been published (message is not mandatory)

        # Gracefully disconnect from broker and exit
        logger.debug 'Disconnecting from broker'
        mqtt_client.disconnect

        if do_exit
          # Exit from process
          status_code = shutdown_ok ? 0 : 1
          logger.debug "Exiting with status code #{status_code}"
          exit status_code
        end
      end

      def on_shutdown=(callback)
        @on_shutdown = callback if callback.is_a?(Proc)
      end

      def on_start(packet = nil, &block)
        if block_given?
          @on_start = block
          return
        end
        # Call user code
        @on_start.call(packet) if @on_start

        configs = packet.payload || {}
        interval = configs['aliveTimeout'] || 1000
        # Start code execution from scratch
        logger.debug "Received 'start'"
        @status = :started
        start_sending_alive interval: interval
      end

      def on_start=(callback)
        @on_start = callback if callback.is_a?(Proc)
      end

      def on_stop(&block)
        if block_given?
          @on_stop = block
          return
        end
        @on_stop.call if @on_stop
        @status = :stopped
        # Stop code excution, but keep broker connection and continue to send alive
      end

      def on_stop=(callback)
        @on_stop = callback if callback.is_a?(Proc)
      end

      def platform
        RUBY_
      end

      def remove_action(action)
        topic = topic_for source: :core, action: action
        mqtt_client.remove_topic_callback topic
      end

      def shutdown(do_exit = true)
        on_shutdown do_exit
      end

      def start
        on_start
      end

      def start_sending_alive(interval: 5000)
        # TODO: replace the alive interval task with Eventmachine?
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

          @setted_up = true
        end
      end

      def topic_for(source: self.name, dest: self.name, action: nil, packet_type: :msg)
        source = source.to_s
        packet_type = packet_type.to_s
        dest = dest.to_s
        action = action.to_s

        Config::DEFAULT_TOPIC_FORMAT % [source, packet_type, dest, action]
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
        mqtt_client.subscribe [topic_for(source: '+', action: '+'), 2]
      end

      # @note Call super if you override this method
      def on_client_suback
        # Client subscribed, we're ready to rock -> Tell core
        logger.debug 'Subscriptions done'
        logger.debug "Sending 'ready' to core"
        message_to :core, :ready
      end

      # @note Call super if you override this method
      def on_client_unsuback
      end

      # @note Call super if you override this method
      def on_client_puback(message)
      end

      # @note Call super if you override this method
      def on_client_pubrel(message)
      end

      # @note Call super if you override this method
      def on_client_pubrec(message)
      end

      # @note Call super if you override this method
      def on_client_pubcomp(message)
      end

      # @note Call super if you override this method
      def on_client_message(message)
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

      def default_actions
        {
            start:    proc { |packet| on_start packet },
            stop:     proc { on_stop },
            restart:  proc { |packet| on_restart packet },
            shutdown: proc { on_shutdown },
            logger:   proc { |packet| on_logger packet }
        }
      end

      def load_fbx_file
        if File.exists? @fbxfile_path
          @fbxfile = YAML.load(File.read(@fbxfile_path)).deep_symbolize_keys
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
            on_puback:        proc { |msg| on_client_puback msg },
            on_pubrel:        proc { |msg| on_client_pubrel msg },
            on_pubrec:        proc { |msg| on_client_pubrec msg },
            on_pubcomp:       proc { |msg| on_client_pubcomp msg },
            on_message:       proc { |msg| on_client_message msg }
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