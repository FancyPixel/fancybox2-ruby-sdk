describe Fancybox2::Module::Base do
  let(:module_base_klass) { Fancybox2::Module::Base }
  let(:mqtt_client) { PahoMqtt::Client.new Mosquitto::LISTENER_CONFIGS }
  let(:path_of_fbxfile_example) { File.join File.dirname('.'), 'Fbxfile.example' }
  let(:example_fbxfile) { YAML.load(File.read(path_of_fbxfile_example)).deep_symbolize_keys }
  let(:module_base) { Fancybox2::Module::Base.new path_of_fbxfile_example, mqtt_client: mqtt_client }
  let(:mqtt_client_params) { { host: 'some_valid_host', port: 2000 } }
  let(:log_level) { Logger::UNKNOWN }
  let(:log_progname) { 'Fancy Program' }
  let(:logger) { Logger.new STDOUT }

  subject { module_base }

  it { is_expected.to have_attr_reader :logger, :mqtt_client, :fbxfile, :fbxfile_path, :configs }

  describe 'initialize' do
    context 'with default params' do
      it 'is expected to set a logger' do
        expect(module_base.logger).to_not be_nil
      end

      it 'is expected the logger to be a Fancybox2::Logger::Multi' do
        expect(module_base.logger).to be_a Fancybox2::Logger::Multi
      end

      it 'is expected the multi logger to include loggers logging on [STDOUT, MQTTLogDevice]' do
        expect(module_base.logger.loggers[0].instance_variable_get(:@logdev).dev).to eq STDOUT
        expect(module_base.logger.loggers[1].instance_variable_get(:@logdev).dev).to be_a Fancybox2::Logger::MQTTLogDevice
      end
    end

    context 'allowed options' do
      context ':mqtt_client' do
        it 'is expected to accept the option and set its value on instance' do
          base_instance = module_base_klass.new path_of_fbxfile_example, mqtt_client: mqtt_client
          expect(base_instance.mqtt_client).to eq mqtt_client
        end

        it "is expected to keep :mqtt_client value only if its not nil" do
          base_instance = module_base_klass.new path_of_fbxfile_example, mqtt_client: nil
          expect(base_instance.mqtt_client).to_not eq nil
        end
      end

      context ':mqtt_client_params' do
        it 'is expected to accept the option and set its value on instance' do
          base_instance = module_base_klass.new path_of_fbxfile_example, mqtt_client_params: mqtt_client_params
          expect(base_instance.instance_variable_get :@mqtt_client_params).to eq mqtt_client_params
        end

        it 'is expected to default to an empty Hash if the value is nil' do
          base_instance = module_base_klass.new path_of_fbxfile_example, mqtt_client_params: nil
          expect(base_instance.instance_variable_get :@mqtt_client_params).to eq({})
        end
      end

      context ':log_level' do
        it 'is expected to accept the option and set its value on instance' do
          base_instance = module_base_klass.new path_of_fbxfile_example, log_level: log_level
          expect(base_instance.instance_variable_get :@log_level).to eq log_level
        end

        it 'is expected to default to Logger::INFO if option is not provided' do
          base_instance = module_base_klass.new path_of_fbxfile_example
          expect(base_instance.instance_variable_get :@log_level).to eq Logger::INFO
        end
      end

      context ':log_progname' do
        it 'is expected to accept the option and set its value on instance' do
          base_instance = module_base_klass.new path_of_fbxfile_example, log_progname: log_progname
          expect(base_instance.instance_variable_get :@log_progname).to eq log_progname
        end

        it 'is expected to default to Fancybox2::Module::Base if option has not been provided' do
          base_instance = module_base_klass.new path_of_fbxfile_example
          expect(base_instance.instance_variable_get :@log_progname).to eq 'Fancybox2::Module::Base'
        end

        it 'is expected to accept a nil value' do
          base_instance = module_base_klass.new path_of_fbxfile_example, log_progname: nil
          expect(base_instance.instance_variable_get :@log_progname).to be_nil
        end
      end

      it 'is expected to accept :logger option and set @logger on instance' do
        base_instance = module_base_klass.new path_of_fbxfile_example, logger: logger
        expect(base_instance.logger).to eq logger
      end

      it 'is expected to accept :fbxfile option and set @fbxfile on instance' do
        fbxfile = { some: 'option' }
        base_instance = module_base_klass.new path_of_fbxfile_example, fbxfile: fbxfile
        expect(base_instance.fbxfile).to eq fbxfile
      end

      it 'is expected to accept :fbxfile_path option and set @fbxfile_path on instance' do
        allow_any_instance_of(module_base_klass).to receive(:load_fbx_file).and_return({})
        fbxfile_path = '/some/path'
        base_instance = module_base_klass.new fbxfile_path
        expect(base_instance.fbxfile_path).to eq fbxfile_path
      end
    end
  end

  describe '#alive_message_data' do
    let(:code_proc) { proc { puts 'hello' } }

    context 'when a block is given' do
      it 'is expected to accept a block and set its value on @alive_message_data' do
        module_base.alive_message_data(&code_proc)
        expect(module_base.instance_variable_get :@alive_message_data).to eq code_proc
      end
    end

    context 'when no block is passed' do
      it 'is expected to call the block if it was previously provided' do
        module_base.alive_message_data(&code_proc)
        expect(code_proc).to receive(:call)
        module_base.alive_message_data
      end
    end
  end

  describe '#alive_message_data=()' do
    let(:code_proc) { proc { puts 'hello' } }

    context 'when passed argument is a Proc' do
      it 'is expected to set @alive_message_data' do
        module_base.alive_message_data = code_proc
        expect(module_base.instance_variable_get :@alive_message_data).to eq code_proc
      end
    end

    context 'when passed argument is not a Proc' do
      let(:not_a_proc) { 'definitely_not_a_proc' }

      it 'is expected to not set @alive_message_data' do
        module_base.alive_message_data = not_a_proc
        expect(module_base.instance_variable_get :@alive_message_data).to_not eq not_a_proc
      end
    end
  end

  describe '#message_to' do
    let(:destination) { :core }
    let(:action) { :test }
    let(:payload) { '' }
    let(:hash_payload) { { some: 'value' } }
    let(:array_payload) { ['some', 'values'] }
    let(:retain) { false }
    let(:qos) { 2 }
    let(:topic) { module_base.topic_for(dest: destination, action: action) }

    context 'when the mqtt_client is connected to the broker' do
      before { module_base.mqtt_client.connect }

      it 'is expected to call mqtt_client#publish' do
        expect(module_base.mqtt_client).to receive(:publish).with topic, payload, retain, qos
        module_base.message_to :core, :test, payload, retain, qos
      end

      it 'is expected to serialize as JSON an Hash payload' do
        expect(module_base.mqtt_client).to receive(:publish).with topic, hash_payload.to_json, retain, qos
        module_base.message_to :core, :test, hash_payload
      end

      it 'is expected to serialize as JSON an Array payload' do
        expect(module_base.mqtt_client).to receive(:publish).with topic, array_payload.to_json, retain, qos
        module_base.message_to :core, :test, array_payload
      end
    end

    context 'when the mqtt_client is NOT connected to the broker' do
      it 'is expected to log an error' do
        expect(module_base.logger).to receive(:error)
        module_base.message_to :core, :test, payload
      end
    end
  end

  describe '#name' do
    it 'is expected to return module name present on Fbxfile.example' do
      expect(module_base.name).to eq example_fbxfile[:name]
    end
  end

  describe '#on_action' do
    before { mqtt_client.connect }

    it 'is expected to add a topic callback on mqtt_client' do
      expect { module_base.on_action(:some_action, proc {}) }
          .to change(module_base.mqtt_client.registered_callback, :size).by 1
    end
  end

  describe '#on_configs' do
    let(:code_proc) { proc { puts 'hello' } }
    let(:json_packet) { double('Some json packet', payload: '{"some": "property"}') }
    let(:yaml_packet) { double('Some yaml packet', payload: "---\n:a: 20\n:b: 10\n") }
    let(:complex_packet) { double('Some yaml packet', payload: "something:\n  not:\n yaml_or_json") }

    it 'is expected to accept a block and set its value on @on_configs' do
      module_base.on_configs(&code_proc)
      expect(module_base.instance_variable_get :@on_configs).to eq code_proc
    end

    it 'is expected to call provided block with packet as argument' do
      packet = [json_packet, yaml_packet, complex_packet].sample
      module_base.on_configs(&code_proc)
      expect(code_proc).to receive(:call).with packet
      module_base.on_configs packet
    end

    it 'is expected to try to parse a JSON payload' do
      module_base.on_configs json_packet
      expect(module_base.instance_variable_get :@configs).to eq JSON.parse(json_packet.payload)
    end

    it 'is expected to try to parse a YAML payload' do
      module_base.on_configs yaml_packet
      expect(module_base.instance_variable_get :@configs).to eq YAML.load(yaml_packet.payload)
    end

    it 'is expected to fallback to original packet payload if any parsing attempt failed' do
      module_base.on_configs complex_packet
      expect(module_base.instance_variable_get :@configs).to eq complex_packet.payload
    end
  end

  describe '#on_configs=()' do
    let(:code_proc) { proc { puts 'hello' } }

    it 'is expected to accept a callback and set its value on @on_configs' do
      module_base.on_configs = code_proc
      expect(module_base.instance_variable_get :@on_configs).to eq code_proc
    end
  end

  describe '#on_logger' do
    let(:code_proc) { proc { puts 'hello' } }
    let(:packet) { double('Some packet', payload: { 'level' => 'debug' }) }

    it 'is expected to accept a block and set its value on @on_logger' do
      module_base.on_logger(&code_proc)
      expect(module_base.instance_variable_get :@on_logger).to eq code_proc
    end

    it 'is expected to call provided block with packet as argument' do
      module_base.on_logger(&code_proc)
      expect(code_proc).to receive(:call).with packet
      module_base.on_logger packet
    end

    it 'is expected to set the log level if present into the packet' do
      expect{ module_base.on_logger packet }.to change(module_base.logger, :level).from(Logger::INFO).to Logger::DEBUG
    end
  end

  describe '#on_logger=' do
    let(:callback) { proc { puts 'hello' } }

    it 'is expected to accept a callback and assign it to @on_logger' do
      module_base.on_logger = callback
      expect(module_base.instance_variable_get :@on_logger).to eq callback
    end
  end

  describe '#on_restart' do
    let(:packet) { double('Some packet', payload: { 'aliveTimeout' => 1000 }) }

    before { mqtt_client.connect }

    context 'when a block is provided' do
      let(:block) { proc { puts 'hello' } }

      it 'is expected to accept a block and set its value on @on_restart' do
        module_base.on_restart(&block)
        expect(module_base.instance_variable_get :@on_restart).to eq block
      end

      it 'is expected to call provided block with packet as argument' do
        module_base.on_restart(&block)
        expect(block).to receive(:call).with packet
        module_base.on_restart packet
      end
    end

    it 'is expected to call #on_stop' do
      expect(module_base).to receive(:on_stop)
      module_base.on_restart packet
    end

    it 'is expected to call #on_start with packet as argument' do
      expect(module_base).to receive(:on_start).with packet
      module_base.on_restart packet
    end
  end

  describe '#on_restart=' do
    let(:callback) { proc { puts 'hello' } }

    it 'is expected to accept a callback and assign it to @on_restart' do
      module_base.on_restart = callback
      expect(module_base.instance_variable_get :@on_restart).to eq callback
    end
  end

  describe '#on_shutdown' do
    before do
      module_base.setup
      module_base.start_sending_alive interval: 1000
      allow(module_base).to receive(:exit).with(any_args).and_return false
    end

    context 'when a block is provided' do
      let(:block) { proc { puts 'something' } }

      before { module_base.on_shutdown(&block) }

      it 'is expected to assign the block to @on_shutdown' do
        expect(module_base.instance_variable_get :@on_shutdown).to eq block
      end

      context 'when a shutdown command is received' do
        it 'is expected to call user code if provided' do
          on_shutdown = module_base.instance_variable_get :@on_shutdown
          expect(on_shutdown).to receive(:call)
          module_base.on_shutdown
        end

        it 'is expected to rescue any StandardError that may occur during user code execution' do
          # Temporary suppress error log messages
          allow(module_base.logger).to receive(:error).and_return nil
          on_shutdown = module_base.instance_variable_get :@on_shutdown
          allow(on_shutdown).to receive(:call).and_raise(StandardError)
          expect { module_base.on_shutdown }.to_not raise_error
        end
      end
    end

    it 'is expected to call @alive_task#shutdown' do
      expect(module_base.instance_variable_get :@alive_task).to receive :shutdown
      module_base.on_shutdown
    end

    it 'is expected to signal core shutdown' do
      expect(module_base).to receive(:message_to).with :core, :shutdown, any_args
      module_base.on_shutdown
    end

    it 'is expected to call mqtt_client#disconnect' do
      expect(mqtt_client).to receive :disconnect
      module_base.on_shutdown
    end

    it 'is expected to exit with a 0 status code' do
      expect(module_base).to receive(:exit).with 0
      module_base.on_shutdown
    end
  end

  describe '#on_shutdown=' do
    let(:callback) { proc { puts 'hello' } }

    it 'is expected to accept a callback and assign it to @on_shutdown' do
      module_base.on_shutdown = callback
      expect(module_base.instance_variable_get :@on_shutdown).to eq callback
    end
  end

  describe '#on_start' do
    let(:interval) { 1000 }
    let(:packet) { double('Some packet', payload: { 'aliveTimeout' => interval }) }

    before { mqtt_client.connect }

    context 'when a block is provided' do
      let(:block) { proc { puts 'hello' } }

      it 'is expected to accept a block and set its value on @on_restart' do
        module_base.on_start(&block)
        expect(module_base.instance_variable_get :@on_start).to eq block
      end

      it 'is expected to call provided block with packet as argument' do
        module_base.on_start(&block)
        expect(block).to receive(:call).with packet
        module_base.on_start packet
      end
    end

    it 'is expected to call #start_sending_alive with interval argument' do
      expect(module_base).to receive(:start_sending_alive).with interval: interval
      module_base.on_start packet
    end

    it 'is expected to set @status = :running' do
      # Set a fake value on @status in order to check if it changes
      module_base.instance_variable_set :@status, 'some value'
      module_base.on_restart packet
      expect(module_base.instance_variable_get :@status).to eq :running
    end

    it 'is expected to call #on_start with packet as argument' do
      expect(module_base).to receive(:on_start).with packet
      module_base.on_restart packet
    end
  end

  describe '#on_start=' do
    let(:callback) { proc { puts 'hello' } }

    it 'is expected to accept a callback and assign it to @on_start' do
      module_base.on_start = callback
      expect(module_base.instance_variable_get :@on_start).to eq callback
    end
  end

  describe '#on_stop' do
    context 'when a block is provided' do
      let(:block) { proc { puts 'hello' } }

      it 'is expected to accept a block and set its value on @on_stop' do
        module_base.on_stop(&block)
        expect(module_base.instance_variable_get :@on_stop).to eq block
      end

      it 'is expected to call provided block' do
        module_base.on_stop(&block)
        expect(block).to receive(:call)
        module_base.on_stop
      end
    end

    it 'is expected to set @status = :stopped' do
      # Set a fake value on @status in order to check if it changes
      module_base.instance_variable_set :@status, 'some value'
      module_base.on_stop
      expect(module_base.instance_variable_get :@status).to eq :stopped
    end
  end

  describe '#on_stop=' do
    let(:callback) { proc { puts 'hello' } }

    it 'is expected to accept a callback and assign it to @on_stop' do
      module_base.on_stop = callback
      expect(module_base.instance_variable_get :@on_stop).to eq callback
    end
  end

  describe '#remove_action' do
    let(:action) { 'some_action' }

    before do
      mqtt_client.connect
      module_base.on_action(action {})
    end

    it 'is expected to remove a topic callback on mqtt_client' do
      expect { module_base.remove_action action }
          .to change(module_base.mqtt_client.registered_callback, :size).by(-1)
    end
  end

  describe '#shutodown' do
    context 'when no argument is provided' do
      it "is expected to call #on_shutdown with an argument that has 'true' value" do
        expect(module_base).to receive(:on_shutdown).with true
        module_base.shutdown
      end
    end

    context "when 'do_exit' argument is provided" do
      let(:do_exit) { false }

      it "is expected to call #on_shutdown with an argument that has provided argument's value" do
        expect(module_base).to receive(:on_shutdown).with do_exit
        module_base.shutdown do_exit
      end
    end
  end

  describe '#start' do
    it 'is expected to call #on_start' do
      expect(module_base).to receive :on_start
      module_base.start
    end
  end

  describe '#start_sending_alive' do
    let(:interval) { 1000 }

    before { mqtt_client.connect }

    it 'is expected to change @alive_task value' do
      before_value = module_base.instance_variable_get :@alive_task
      module_base.start_sending_alive(interval: interval)
      expect(module_base.instance_variable_get :@alive_task).to_not eq before_value
    end

    it 'is expected to populate @alive_task variable with an instance of Concurrent::TimerTask' do
      expect(module_base.start_sending_alive(interval: interval)).to be_a Concurrent::TimerTask
    end

    it 'is expected to call #shutdown on @alive_task if the task already existed' do
      module_base.start_sending_alive interval: interval
      expect(module_base.instance_variable_get :@alive_task).to receive :shutdown
      module_base.start_sending_alive interval: interval
    end
  end

  describe '#setup' do
    after { module_base.shutdown false }

    context 'when #setup has never been called' do
      it 'is expected to call mqtt_client#connect' do
        expect(mqtt_client).to receive :connect
        module_base.setup
      end
    end

    context 'when #setup has already been called' do
      before { module_base.setup }

      it "is expected to don't call mqtt_client#connect" do
        expect(mqtt_client).to_not receive :connect
        module_base.setup
      end
    end

  #   context 'when a connection error occurs' do
  #     # Override mqtt_client with a special one that has no reconnection retries and so on...
  #     let(:mqtt_client) do
  #       PahoMqtt::Client.new Mosquitto::LISTENER_CONFIGS.merge(
  #           reconnect_limit: 0,
  #           reconnect_delay: 0,
  #           keep_alive: 0,
  #           ack_timeout: 0
  #       )
  #     end
  #
  #     before(:all) { Mosquitto.stop }
  #     after(:all) do
  #       # Restart Mosquitto
  #       Mosquitto.start
  #       sleep(10) # Give time to mosquitto to startup
  #     end
  #
  #     # We expect to rescue the raised exception
  #     it 'is expected to not raise an error' do
  #       expect { module_base.setup(false) }.to_not raise_error
  #     end
  #   end
  end

  describe '#topic_for' do
    let(:dest) { :some_dest }
    let(:action) { :some_action }
    let(:packet_type) { :some_destination_type }

    it 'is expected to return a topic that includes both the destination and the action provided' do
      expect(module_base.topic_for dest: dest, action: action).to include(dest.to_s, action.to_s)
    end

    it "is expected to return a topic that includes 'packet_type' if provided" do
      expect(module_base.topic_for dest: dest, action: action, packet_type: packet_type).to include(packet_type.to_s)
    end
  end

  describe '#on_client_connack' do
    before { module_base.mqtt_client.connect }

    it 'is expected to call #on_action for each action configured in #default_actions' do
      expect(module_base).to receive(:on_action).exactly(module_base.send(:default_actions).keys.size).times
      module_base.on_client_connack
    end

    it 'is expected to call #mqtt_client#subscribe with appropriate params' do
      expect(module_base.mqtt_client).to receive(:subscribe).with([module_base.topic_for(source: '+', action: '+'), 2])
      module_base.on_client_connack
    end
  end

  describe '#on_client_suback' do
    it 'is expected to signal core of module readiness' do
      expect(module_base).to receive(:message_to).with(:core, :ready)
      module_base.on_client_suback
    end
  end

  context 'private methods' do

    describe '#check_or_build_mqtt_client' do
      context 'when no mqtt_client param is provided' do
        it 'is expected to return a PahoMqtt::Client instance' do
          expect(module_base.send :check_or_build_mqtt_client).to be_a PahoMqtt::Client
        end

        it 'is expected to call #mqtt_params' do
          expect(module_base).to receive(:mqtt_params)
          module_base.send :check_or_build_mqtt_client
        end
      end

      context 'when mqtt_client param is provided' do
        context "and it's not a valid client" do
          it 'is expected to raise a NotValidMQTTClient exception' do
            expect { module_base.send(:check_or_build_mqtt_client, 'not_a_client') }.to raise_error Fancybox2::Module::Exceptions::NotValidMQTTClient
          end
        end
      end
    end

    describe '#check_and_return_fbxfile' do
      let(:fake_fbxfile_content) { { a: 1, 'b' => 2 } }

      it 'is expected to return an Hash' do
        expect(module_base.send(:check_and_return_fbxfile, fake_fbxfile_content)).to be_a Hash
      end

      it 'is expected to return an Hash with all symbolized keys' do
        expect(module_base.send(:check_and_return_fbxfile, fake_fbxfile_content).keys).to all(be_a Symbol)
      end

      it 'is expected to raise an ArgumentError if provided param is not an Hash' do
        expect { module_base.send :check_and_return_fbxfile, 'not an Hash' }.to raise_error ArgumentError
      end
    end

    describe '#create_default_logger' do
      it 'is expected to return a Fancybox2::Logger::Multi instance' do
        expect(module_base.send :create_default_logger).to be_a Fancybox2::Logger::Multi
      end

      it 'is expected the returned Multi logger includes a STDOUT and a MQTT broker logger' do
        loggers = module_base.send(:create_default_logger).loggers
        expect(loggers.first.instance_variable_get(:@logdev).dev).to eq STDOUT
        expect(loggers.last.instance_variable_get(:@logdev).dev).to be_a Fancybox2::Logger::MQTTLogDevice
      end

      it 'is expected the broker logger to have a Fancybox2::Logger::JSONFormatter formatter' do
        loggers = module_base.send(:create_default_logger).loggers
        expect(loggers.last.formatter).to be_a Fancybox2::Logger::JSONFormatter
      end

      it 'is expected the broker logdev to use the module_base mqtt_client' do
        loggers = module_base.send(:create_default_logger).loggers
        expect(loggers.last.instance_variable_get(:@logdev).dev.client).to eq module_base.mqtt_client
      end
    end

    describe '#default_actions' do
      it 'is expected to return an Hash of default actions' do
        expect(module_base.send(:default_actions).keys).to eq [:start, :stop, :restart, :shutdown, :logger, :configs]
      end
    end

    describe '#load_fbx_file' do
      context 'when an Fbxfile.example exists at path' do
        it 'it is expected to return the file content as an Hash' do
          expect(module_base.send(:load_fbx_file)).to be_a Hash
        end
      end

      context 'when no Fbxfile.example exists at path' do
        let(:bad_path) { 'bad/path' }

        before { module_base.instance_variable_set :@fbxfile_path, bad_path }

        it 'is expected to raise a Exceptions::FbxfileNotFound' do
          expect { module_base.send :load_fbx_file }.to raise_error Fancybox2::Module::Exceptions::FbxfileNotFound
        end
      end
    end
  end
end
