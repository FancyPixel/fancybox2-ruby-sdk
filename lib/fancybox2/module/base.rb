module Fancybox2
  module Module
    class Base
      include Utils

      attr_accessor :logger, :log_level, :log_progname

      def initialize(options = {})
        options.deep_symbolize_keys!
        @log_level = options[:log_level] || ::Logger::DEBUG
        @log_progname = options[:log_progname] || 'Fancybox2::Module::Base'
        @logger = options[:logger] || build_default_logger
      end

      private

      def build_default_logger
        stdout_logger = ::Logger.new STDOUT
        multi_logger = Logger::Multi.new stdout_logger,
                                         level: @log_level,
                                         progname: @log_progname,
                                         escape_data: true
        multi_logger
      end
    end
  end
end