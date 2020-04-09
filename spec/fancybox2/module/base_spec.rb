require 'spec_helper'

describe Fancybox2::Module::Base do
  let(:module_base_klass) { Fancybox2::Module::Base }
  let(:module_base) { Fancybox2::Module::Base.new }
  let(:mqtt_client) { PahoMqtt::Client.new Mosquitto::LISTENER_CONFIGS }
  let(:mqtt_client_params) { { host: 'some_valid_host', port: 2000 } }
  let(:log_level) { Logger::UNKNOWN }
  let(:log_progname) { 'Fancy Program' }
  let(:logger) { Logger.new STDOUT }
  let(:base_fbxfile) { JSON.load(File.read(File.expand_path('../config/Fbxfile.example', __FILE__))).deep_symbolize_keys }

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
        it 'is expected to accept the option and set provided mqtt_client on instance' do
          base_instance = module_base_klass.new mqtt_client: mqtt_client
          expect(base_instance.mqtt_client).to eq mqtt_client
        end

        it "is expected to keep :mqtt_client value only if its not nil" do
          base_instance = module_base_klass.new mqtt_client: nil
          expect(base_instance.mqtt_client).to_not eq nil
        end
      end

      context ':mqtt_client_options' do
        it 'is expected to accept the option and set @mqtt_client_params on instance' do
          base_instance = module_base_klass.new mqtt_client_params: mqtt_client_params
          expect(base_instance.instance_variable_get(:@mqtt_client_params)).to eq mqtt_client_params
        end

        it 'is expected to default to an empty Hash if the value is nil' do
          base_instance = module_base_klass.new mqtt_client_params: nil
          expect(base_instance.instance_variable_get(:@mqtt_client_params)).to eq({})
        end
      end

      context ':log_level' do
        it 'is expected to accept the option and set the value on its logger' do
          base_instance = module_base_klass.new log_level: log_level
          expect(base_instance.logger.level).to eq log_level
        end

        it 'is expected to default to Logger::DEBUG if option is nil or not provided' do
          base_instance = module_base_klass.new log_level: nil
          expect(base_instance.logger.level).to eq Logger::DEBUG
          base_instance = module_base_klass.new
          expect(base_instance.logger.level).to eq Logger::DEBUG
        end
      end

      context ':log_progname' do
        it 'is expected to accept the option and set the value on its logger' do
          base_instance = module_base_klass.new log_progname: log_progname
          expect(base_instance.logger.progname).to eq log_progname
        end

        it 'is expected to default to Fancybox2::Module::Base if option has not been provided' do
          base_instance = module_base_klass.new
          expect(base_instance.logger.progname).to eq 'Fancybox2::Module::Base'
        end

        it 'is expected to accept a nil value' do
          base_instance = module_base_klass.new log_progname: nil
          expect(base_instance.logger.progname).to be_nil
        end
      end

      it 'is expected to accept :logger option and set @logger in instance' do
        base_instance = module_base_klass.new logger: logger
        expect(base_instance.logger).to eq logger
      end
    end

    describe '#name' do
      it 'is expected to return module name present on config/Fbxfile.example' do
        expect(module_base.name).to eq base_fbxfile[:name]
      end
    end

    describe '#mqtt_client' do
      context 'when the client is set on the instance' do
        before { module_base.mqtt_client = mqtt_client }

        it 'is expected to return provided mqtt_client' do
          expect(module_base.mqtt_client).to eq mqtt_client
        end
      end

      context 'when the client is not provided' do
        it 'is expected to create a new one' do
          expect(module_base.mqtt_client).to be_a PahoMqtt::Client
          expect(module_base.mqtt_client).to_not eq mqtt_client
        end
      end
    end

    describe '#mqtt_client=(client)' do
      let(:not_a_valid_client) { 'not a client at all' }

      it 'is expected to check that the provided client is a PahoMqtt::Client' do
        expect { module_base.mqtt_client = not_a_valid_client }.to raise_error Fancybox2::Module::Exceptions::NotValidMQTTClient
      end

      it 'is expected to populate @mqtt_client instance variable with the provided client' do
        module_base.mqtt_client = mqtt_client
        expect(module_base.instance_variable_get :@mqtt_client).to eq mqtt_client
      end
    end

    describe '#fbxfile' do
      let(:fbxfile_mock) { { name: 'some_name' } }

      context 'when the variable is set on the instance' do
        before { module_base.fbxfile = fbxfile_mock }

        it 'is expected to return set content' do
          expect(module_base.fbxfile).to eq fbxfile_mock
        end
      end

      context 'when the @fbxfile variable value is not yet populated' do
        context 'if the Fbxfile exists' do
          it 'is expected to call #fbxfile_path' do
            expect(module_base).to receive(:fbxfile_path).at_least(:once).and_call_original
            module_base.fbxfile
          end

          it 'is expected to populate @fbxfile variable' do
            fbxfile_var_value = proc { module_base.instance_variable_get(:@fbxfile) }
            expect { module_base.fbxfile }.to change { fbxfile_var_value.call }
            expect(fbxfile_var_value.call).to eq base_fbxfile
          end
        end

        context 'if the Fbxfile does not exist' do
          before { allow(module_base).to receive(:fbxfile_path).and_return('not/a/valid/path') }

          it 'is expected to raise a FbxfileNotFound error' do
            expect { module_base.fbxfile }.to raise_error Fancybox2::Module::Exceptions::FbxfileNotFound
          end
        end
      end
    end

    describe '#fbxfile=' do

    end
  end
end