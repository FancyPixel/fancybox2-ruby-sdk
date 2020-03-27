module Fancybox2

  ##
  # This module contains some utility methods

  module Utils
    extend self

    def build_default_logger
      logger          = Logger::MultiDevice.new
      logger.level    = normalize_log_level :info
      logger.progname = 'Fancybox2'
    end

    ##
    # @param [String] log_level
    def normalize_log_level(log_level = nil)
      case log_level
      when :debug, ::Logger::DEBUG, 'debug' then ::Logger::DEBUG
      when :info,  ::Logger::INFO,  'info'  then ::Logger::INFO
      when :warn,  ::Logger::WARN,  'warn'  then ::Logger::WARN
      when :error, ::Logger::ERROR, 'error' then ::Logger::ERROR
      when :fatal, ::Logger::FATAL, 'fatal' then ::Logger::FATAL
      else
        Logger::ERROR
      end
    end
  end
end
