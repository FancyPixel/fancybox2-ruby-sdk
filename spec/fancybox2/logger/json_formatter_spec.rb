require 'spec_helper'

describe Fancybox2::Logger::JSONFormatter do
  let(:file_logger) { Logger.new File.open($spec_log_file_path, 'w+') }
  let(:formatter) { Fancybox2::Logger::JSONFormatter.new }

  it 'is expected to dump a JSON when used in a logger' do
    message = 'Hello, World!'
    file_logger.formatter = formatter
    file_logger.info message
    file_logger.close
    expect(File.read($spec_log_file_path)).to include message
  end

  describe '#call' do
    let(:formatted_severity) { 'WARN' }
    let(:time) { Time.now }
    let(:progname) { 'THE_PROGRAM' }
    let(:message) { 'A nice log message' }

    it 'is expected to return a JSON formatted string' do
      expect(formatter.call(formatted_severity, time, progname, message)).to be_a String
      expect(JSON.parse(formatter.call(formatted_severity, time, progname, message))).to be_a Hash
    end
  end
end
