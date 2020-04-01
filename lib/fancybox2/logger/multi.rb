require 'logger'

module Fancybox2
  module Logger

    # Log on multiple loggers at the same time
    #
    # Usage example:
    #
    # file_logger = Logger.new(File.open("log/debug.log", "a"))
    # stdout_logger = Logger.new(STDOUT)
    # Create a logger that logs both to STDOUT and log_file at the same time with 'info' loglevel
    # multi_logger = Fancybox2::Logger::Multi.new(file_logger, stdout_logger, level: :info))

    class Multi
      attr_accessor :loggers, :level, :escape_data, :progname

      def initialize(*args)# level: nil, loggers: nil, escape_data: true)
        options = args.extract_options.deep_symbolize_keys
        loggers = args
        if !loggers.is_a?(Array) || loggers.size.zero?
          raise ArgumentError.new("provide at least one logger instance")
        end
        @loggers = []
        @level = options[:level]
        @escape_data = options[:escape_data] || false
        @progname = options[:progname]

        self.loggers = loggers
        define_methods
      end

      def add(level, *args)
        @loggers.each { |logger| logger.add(level, args) }
      end

      def add_logger(logger)
        logger.level = @level if @level
        logger.progname = @progname if @progname
        if escape_data
          escape_data_of logger
        end
        @loggers << logger
      end

      def close
        @loggers.map(&:close)
      end

      def escape_data=(value)
        if value
          @loggers.each do |logger|
            escape_data_of logger
          end
        else
          @loggers.each { |logger| logger.formatter = ::Logger::Formatter.new }
        end
      end

      def level=(level)
        @level = level
        @loggers.each { |logger| logger.level = level }
      end

      def loggers=(loggers)
        loggers.each do |logger|
          # Check if provided loggers are real Loggers
          unless logger.is_a? ::Logger
            raise ArgumentError.new("one of the provided loggers is not of class Logger, but of class '#{logger.class}'")
          end
          # Add Logger to the list
          add_logger logger
        end
      end

      private

      def define_methods
        ::Logger::Severity.constants.each do |level|
          define_singleton_method(level.downcase) do |args|
            @loggers.each { |logger| logger.add(normalize_log_level(level.downcase), *args) }
          end

          define_singleton_method("#{ level.downcase }?".to_sym) do
            @level <= ::Logger::Severity.const_get(level)
          end
        end
      end

      def escape_data_of(logger)
        original_formatter = ::Logger::Formatter.new
        logger.formatter = proc do |severity, datetime, progname, msg|
          original_formatter.call(severity, datetime, progname, msg.dump)
        end
      end

      ##
      # @param [String] log_level
      def normalize_log_level(log_level)
        case log_level
        when :debug, ::Logger::DEBUG, 'debug' then ::Logger::DEBUG
        when :info,  ::Logger::INFO,  'info'  then ::Logger::INFO
        when :warn,  ::Logger::WARN,  'warn'  then ::Logger::WARN
        when :error, ::Logger::ERROR, 'error' then ::Logger::ERROR
        when :fatal, ::Logger::FATAL, 'fatal' then ::Logger::FATAL
        else
          ::Logger::INFO
        end
      end
    end
  end
end
