describe Fancybox2::Module::Base do
  let(:module_base_klass) { Fancybox2::Module::Base }
  let(:mqtt_client) { PahoMqtt::Client.new Mosquitto::LISTENER_CONFIGS }
  let(:module_base) { Fancybox2::Module::Base.new mqtt_client: mqtt_client }
  let(:mqtt_client_params) { { host: 'some_valid_host', port: 2000 } }
  let(:log_level) { Logger::UNKNOWN }
  let(:log_progname) { 'Fancy Program' }
  let(:logger) { Logger.new STDOUT }
  let(:path_of_fbxfile_example) { Fancybox2::Module::Config::FBXFILE_DEFAULT_FILE_PATH }
  let(:example_fbxfile) { JSON.load(File.read(path_of_fbxfile_example)).deep_symbolize_keys }

  context 'attr_accessors' do
    it { should have_attr_reader :logger }
  end

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
          base_instance = module_base_klass.new mqtt_client: mqtt_client
          expect(base_instance.mqtt_client).to eq mqtt_client
        end

        it "is expected to keep :mqtt_client value only if its not nil" do
          base_instance = module_base_klass.new mqtt_client: nil
          expect(base_instance.mqtt_client).to_not eq nil
        end
      end

      context ':mqtt_client_params' do
        it 'is expected to accept the option and set its value on instance' do
          base_instance = module_base_klass.new mqtt_client_params: mqtt_client_params
          expect(base_instance.instance_variable_get :@mqtt_client_params).to eq mqtt_client_params
        end

        it 'is expected to default to an empty Hash if the value is nil' do
          base_instance = module_base_klass.new mqtt_client_params: nil
          expect(base_instance.instance_variable_get :@mqtt_client_params).to eq({})
        end
      end

      context ':log_level' do
        it 'is expected to accept the option and set its value on instance' do
          base_instance = module_base_klass.new log_level: log_level
          expect(base_instance.instance_variable_get :@log_level).to eq log_level
        end

        it 'is expected to default to Logger::INFO if option is not provided' do
          base_instance = module_base_klass.new
          expect(base_instance.instance_variable_get :@log_level).to eq Logger::INFO
        end
      end

      context ':log_progname' do
        it 'is expected to accept the option and set its value on instance' do
          base_instance = module_base_klass.new log_progname: log_progname
          expect(base_instance.instance_variable_get :@log_progname).to eq log_progname
        end

        it 'is expected to default to Fancybox2::Module::Base if option has not been provided' do
          base_instance = module_base_klass.new
          expect(base_instance.instance_variable_get :@log_progname).to eq 'Fancybox2::Module::Base'
        end

        it 'is expected to accept a nil value' do
          base_instance = module_base_klass.new log_progname: nil
          expect(base_instance.instance_variable_get :@log_progname).to be_nil
        end
      end

      it 'is expected to accept :logger option and set @logger on instance' do
        base_instance = module_base_klass.new logger: logger
        expect(base_instance.logger).to eq logger
      end

      it 'is expected to accept :fbxfile option and set @fbxfile on instance' do
        fbxfile = { some: 'option' }
        base_instance = module_base_klass.new fbxfile: fbxfile
        expect(base_instance.fbxfile).to eq fbxfile
      end

      it 'is expected to accept :fbxfile_path option and set @fbxfile_path on instance' do
        allow_any_instance_of(module_base_klass).to receive(:load_fbx_file).and_return({})
        fbxfile_path = '/some/path'
        base_instance = module_base_klass.new fbxfile_path: fbxfile_path
        expect(base_instance.fbxfile_path).to eq fbxfile_path
      end
    end

    describe '#default_actions' do
      it 'is expected to return an Hash of default actions' do
        expect(module_base.default_actions.keys).to include :start, :stop, :restart, :shutdown, :logger
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

  describe '#name' do
    it 'is expected to return module name present on config/Fbxfile' do
      expect(module_base.name).to eq example_fbxfile[:name]
    end
  end

  describe '#on_action' do
    let(:base_module) { module_base_klass.new mqtt_client: mqtt_client }

    before { mqtt_client.connect }

    it 'is expected to add a topic callback on mqtt_client' do
      expect { base_module.on_action(:some_action, proc {}) }
          .to change(base_module.mqtt_client.registered_callback, :size).by 1
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

  describe '#remove_action' do
    let(:base_module) { module_base_klass.new mqtt_client: mqtt_client }
    let(:action) { 'some_action' }

    before do
      mqtt_client.connect
      base_module.on_action(action {})
    end

    it 'is expectedt to remove a topic callback on mqtt_client' do
      expect { base_module.remove_action action }
          .to change(base_module.mqtt_client.registered_callback, :size).by(-1)
    end
  end

  describe '#on_restart' do
    let(:packet) { 'fake packet' }

    it 'is expected to call #stop' do
      allow(module_base).to receive(:on_start).and_return(nil)
      expect(module_base).to receive(:on_stop)
      module_base.on_restart(packet)
    end

    it 'is expected to call #start' do
      expect(module_base).to receive(:on_start).with(packet)
      module_base.on_restart(packet)
    end
  end

  describe '#start_sending_alive' do
    let(:interval) { 1000 }

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
  end

  describe '#on_shutdown' do
    before do
      module_base.setup
      module_base.start_sending_alive interval: 1000
      allow(module_base).to receive(:exit).with(any_args).and_return false
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

  describe '#fbxfile_path' do
    context 'when the @fbxfile_path variable is set on the instance' do
      let(:file_path) { '/some/path' }

      before { module_base.instance_variable_set(:@fbxfile_path, file_path) }

      it 'is expected to return the set variable content' do
        expect(module_base.fbxfile_path).to eq file_path
      end
    end

    context 'when the @fbxfile_path variable value is not yet populated' do
      it 'is expected to return Fancybox2::Module::Config::FBXFILE_DEFAULT_FILE_PATH' do
        expect(module_base.fbxfile_path).to eq Fancybox2::Module::Config::FBXFILE_DEFAULT_FILE_PATH
      end
    end
  end
end
