require 'spec_helper'

describe Fancybox2::Module::Base do
  let(:module_base_klass) { Fancybox2::Module::Base }
  let(:mqtt_client) { PahoMqtt::Client.new Mosquitto::LISTENER_CONFIGS }
  let(:module_base) { Fancybox2::Module::Base.new }
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

        it 'is expected to default to Logger::DEBUG if option is not provided' do
          base_instance = module_base_klass.new
          expect(base_instance.instance_variable_get :@log_level).to eq Logger::DEBUG
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

    describe '#on_action' do
      let(:base_module) { module_base_klass.new mqtt_client: mqtt_client }
      before { base_module.setup }

      it 'is expected to ad da topic callback on mqtt_client' do
        expect { base_module.on_action :some_action, proc {} }
            .to change(base_module.mqtt_client.registered_callback, :size).by 1
      end
    end

    describe '#alive' do

    end

    describe '#default_actions' do
      it 'is expected to return an array of default actions' do
        expect(module_base.default_actions).to eq %w(start  stop  restart  shutdown  logger)
      end
    end

    describe '#name' do
      it 'is expected to return module name present on config/Fbxfile' do
        expect(module_base.name).to eq example_fbxfile[:name]
      end
    end

    describe '#message_to' do

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
end