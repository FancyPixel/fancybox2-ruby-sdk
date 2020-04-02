require 'spec_helper'
require 'logger'

describe Fancybox2::Logger::Multi do
  let(:stdout_logger) { Logger.new STDOUT }

  context 'attr_accessors' do
    subject(:multi_logger_class) { Fancybox2::Logger::Multi.new stdout_logger}

    it { is_expected.to have_attr_reader :loggers }
    it { is_expected.to have_attr_reader :level }
    it { is_expected.to have_attr_reader :escape_data }
    it { is_expected.to have_attr_reader :progname }
  end

  describe 'initialize' do
    it 'is expected to raise an error if at least one logger is not provided' do
      expect { Fancybox2::Logger::Multi.new }.to raise_error ArgumentError
    end

    it 'is expected to set loggers on instance' do
      multi = Fancybox2::Logger::Multi.new stdout_logger
      expect(multi.loggers).to eq [stdout_logger]
    end

    it 'is expected to define Ruby Logger severities methods [debug, info, warn, error, fatal, unknown]' do
      multi = Fancybox2::Logger::Multi.new stdout_logger
      Logger::Severity.constants.each do |severity|
        expect(multi).to respond_to severity.downcase.to_sym
      end
    end

    context 'options' do
      let(:level) { Logger::INFO }
      let(:escape_data) { true }
      let(:progname) { 'NICE_PROGRAM' }

      it "is expected to accept 'level' and set its value on instance" do
        multi = Fancybox2::Logger::Multi.new stdout_logger, level: level
        expect(multi.level).to eq level
      end

      it "is expected to accept 'escape_data' and set its value on instance" do
        multi = Fancybox2::Logger::Multi.new stdout_logger, escape_data: escape_data
        expect(multi.escape_data).to eq escape_data
      end

      it "is expected to default 'escape_data' to false" do
        multi = Fancybox2::Logger::Multi.new stdout_logger, escape_data: false
        expect(multi.escape_data).to eq false
      end

      it "is expected to accept 'progname' and set its value on instance" do
        multi = Fancybox2::Logger::Multi.new stdout_logger, progname: progname
        expect(multi.progname).to eq progname
      end
    end

  end
end
