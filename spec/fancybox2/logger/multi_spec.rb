require 'spec_helper'
require 'logger'

describe Fancybox2::Logger::Multi do
  let(:stdout_logger) { Logger.new STDOUT }
  let(:file_logger) { Logger.new File.open($spec_log_file_path, 'w+') }

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

    it 'is expected to set log level on every provided logger' do
      level = Logger::WARN
      Fancybox2::Logger::Multi.new stdout_logger, file_logger, level: level
      expect(stdout_logger.level).to eq level
      expect(file_logger.level).to eq level
    end

    it 'is expected to set progname on every provided logger' do
      progname = 'NICE_PROGRAM'
      Fancybox2::Logger::Multi.new stdout_logger, file_logger, progname: progname
      expect(stdout_logger.progname).to eq progname
      expect(file_logger.progname).to eq progname
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

  describe '#add' do
    let(:multi) { Fancybox2::Logger::Multi.new stdout_logger, file_logger }
    let(:log_level) { Logger::INFO }
    let(:log_message) { "log message" }

    it "is expected to forward the call to #add to every configured logger" do
      expect(stdout_logger).to receive(:add).with log_level, log_message
      multi.add log_level, log_message
    end
  end

  describe '#add_logger' do
    let(:multi) { Fancybox2::Logger::Multi.new stdout_logger }

    it 'is expected to add the provided logger to the list' do
      multi.add_logger file_logger
      expect(multi.loggers).to include file_logger
    end

    it "is expected to have an alias method called 'log'" do
      expect(multi).to respond_to :log
    end
  end

  describe '#close' do
    let(:multi) { Fancybox2::Logger::Multi.new stdout_logger, file_logger }

    it 'is expected to call #close on every configured logger' do
      expect(stdout_logger).to receive :close
      expect(file_logger).to receive :close
      multi.close
    end
  end

  describe '#escape_data=(value)' do
    let(:multi) { Fancybox2::Logger::Multi.new file_logger }
    let(:bad_message) { 'a very nasty "" message' }

    context 'when value is true' do
      it 'is expected to configure, on every logger, a Logger::Formatter with escaped (dumped) log messages' do
        multi.escape_data = true
        multi.info bad_message
        multi.close
        expect(File.read($spec_log_file_path)).to include bad_message.dump
      end
    end

    context 'when value is false' do
      it 'is expected to configure, on every logger, a Logger::Formatter without escaped log messages' do
        multi.escape_data = false
        multi.info bad_message
        multi.close
        expect(File.read($spec_log_file_path)).to include bad_message
      end
    end
  end

  describe '#level=(level)' do
    let(:multi) { Fancybox2::Logger::Multi.new stdout_logger, file_logger }
    let(:level) { Logger::WARN }

    it 'is expected to configure provided log level on every logger' do
      multi.level = level
      expect(stdout_logger.level).to eq level
      expect(file_logger.level).to eq level
    end
  end

  describe '#loggers=(loggers)' do
    let(:multi) { Fancybox2::Logger::Multi.new stdout_logger, file_logger }
    let(:new_loggers) { [Logger.new(STDERR), Logger.new(STDIN)] }

    it 'is expected to replace loggers with provided ones' do
      multi.loggers = new_loggers
      expect(multi.loggers).to match_array new_loggers
    end
  end

  describe '#progname=(name)' do
    let(:multi) { Fancybox2::Logger::Multi.new stdout_logger, file_logger }
    let(:progname) { 'THE_PROG' }

    it 'is expected to set progname on every provided logger' do
      multi.progname = progname
      expect(stdout_logger.progname).to eq progname
      expect(file_logger.progname).to eq progname
    end
  end
end
