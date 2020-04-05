require 'spec_helper'
require 'paho-mqtt'

describe Fancybox2::Logger::MQTTLogDevice do
  let(:mqtt_client) { PahoMqtt::Client.new }
  let(:topic) { 'the_topic' }

  context 'attr_accessors' do
    subject(:log_device_class) { Fancybox2::Logger::MQTTLogDevice.new client: mqtt_client }

    it { is_expected.to have_attr_reader :client }
    it { is_expected.to have_attr_reader :topic }
  end

  describe 'initialize' do
    it "is expected to accept 'client' param and set its value on instance" do
      logdev = Fancybox2::Logger::MQTTLogDevice.new client: mqtt_client
      expect(logdev.client).to eq mqtt_client
    end

    it "is expected to raise an ArgumentError if provided client does not respond to '#publish'" do
      expect { Fancybox2::Logger::MQTTLogDevice.new client: "not_a_client" }.to raise_error ArgumentError
    end

    it "is expected to set accept 'topic' param and set its value on instance" do
      logdev = Fancybox2::Logger::MQTTLogDevice.new client: mqtt_client, topic: topic
      expect(logdev.topic).to eq topic
    end

    it 'is expected to set a default topic if not provided' do
      logdev = Fancybox2::Logger::MQTTLogDevice.new client: mqtt_client
      expect(logdev.topic).to eq Fancybox2::Logger::MQTTLogDevice::DEFAULT_TOPIC
    end
  end

  describe '#write' do
    let(:logdev) { Fancybox2::Logger::MQTTLogDevice.new client: mqtt_client, topic: topic }
    let(:log_message) { 'a log message' }

    it "is expected to call client#publish with topic and message as arguments" do
      expect(mqtt_client).to receive(:publish).with topic, log_message
      logdev.write(log_message)
    end
  end
end
