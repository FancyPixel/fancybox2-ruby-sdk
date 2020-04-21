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

      # logger_1, logger_2, ... , level: nil, loggers: nil, escape_data: true)
      def initialize(*args)
        options = args.extract_options.deep_symbolize_keys
        loggers = args
        if !loggers.is_a?(Array) || loggers.size.zero?
          raise ArgumentError.new("provide at least one logger instance")
        end

        @level = normalize_log_level(options[:level])
        @escape_data = options[:escape_data] || false
        @progname = options[:progname]

        self.loggers = loggers
        # Set properties
        # Override Loggers levels only if explicitly required
        self.level = @level if options[:level] # Do not use @level because it has already been processed
        # Override Logger's Formatter only if explicitly required
        self.escape_data = @escape_data if @escape_data
        self.progname = @progname if @progname

        define_methods
      end

      def add(level, *args)
        @loggers.each { |logger| logger.add(level, *args) }
      end
      alias log add

      def add_logger(logger)
        @loggers << logger
      end

      def close
        @loggers.map(&:close)
      end

      def default_log_level
        'info'
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
        @level = normalize_log_level(level)
        @loggers.each { |logger| logger.level = level }
      end

      def loggers=(new_loggers)
        @loggers = []
        new_loggers.each do |logger|
          # Check if provided loggers are real Loggers
          unless logger.is_a? ::Logger
            raise ArgumentError.new("one of the provided loggers is not of class Logger, but of class '#{logger.class}'")
          end
          # Add Logger to the list
          add_logger logger
        end
      end

      def progname=(name)
        loggers.each do |logger|
          logger.progname = name
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
        when :unknown, ::Logger::UNKNOWN, 'unknown' then ::Logger::UNKNOWN
        when :debug,   ::Logger::DEBUG,   'debug'   then ::Logger::DEBUG
        when :info,    ::Logger::INFO,    'info'    then ::Logger::INFO
        when :warn,    ::Logger::WARN,    'warn'    then ::Logger::WARN
        when :error,   ::Logger::ERROR,   'error'   then ::Logger::ERROR
        when :fatal,   ::Logger::FATAL,   'fatal'   then ::Logger::FATAL
        else
          # puts "Fancybox2::Logger::Multi#normalize_log_level, log_level value '#{log_level.inspect}' not supported, defaulting to '#{default_log_level}'"
          normalize_log_level(default_log_level)
        end
      end
    end
  end
end
