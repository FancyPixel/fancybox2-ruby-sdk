require 'spec_helper'

describe Fancybox2::Module::Base do
  let(:module_base_klass) { Fancybox2::Module::Base }
  let(:mqtt_client) { PahoMqtt::Client.new }
  let(:mqtt_client_params) { { host: 'some_valid_host', port: '2000' } }
  let(:log_level) { Logger::UNKNOWN }
  let(:log_progname) { 'Fancy Program' }
  let(:logger) { Logger.new STDOUT }

  context 'attr_accessors' do
    it { should have_attr_reader :logger }
  end

  describe 'initialize' do
    let(:module_base) { Fancybox2::Module::Base.new }

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
      it 'is expected to accept a :mqtt_client option and set provided mqtt_client on instance' do
        base_instance = module_base_klass.new mqtt_client: mqtt_client
        expect(base_instance.mqtt_client).to eq mqtt_client
      end

      it 'is expected to accept :mqtt_client_params and set @mqtt_client_params on instance' do
        base_instance = module_base_klass.new mqtt_client_params: mqtt_client_params
        expect(base_instance.instance_variable_get(:@mqtt_client_params)).to eq mqtt_client_params
      end

      it 'is expected to accept :log_level option and set the value on its logger' do
        base_instance = module_base_klass.new log_level: log_level
        expect(base_instance.logger.level).to eq log_level
      end

      it 'is expected to default :log_level to Logger::DEBUG if option is not provided' do
        base_instance = module_base_klass.new
        expect(base_instance.logger.level).to eq Logger::DEBUG
      end

      it 'is expected to accept :log_progname and set the value on its logger' do
        base_instance = module_base_klass.new log_progname: log_progname
        expect(base_instance.logger.progname).to eq log_progname
      end

      it 'is expected to accept :logger option and set @logger in instance' do
        base_instance = module_base_klass.new logger: logger
        expect(base_instance.logger).to eq logger
      end
    end
  end
end