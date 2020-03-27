module Fancybox2
  module Logger

    # Log on multiple outputs at the same time
    #
    # Usage example:
    #
    # log_file = File.open("log/debug.log", "a")
    # broker_device = Fancybox2::Logger::Devices::Broker.new
    # logger = Logger.new(Fancybox2::Logger::MultiDevice.new(STDOUT, log_file, broker_device))  # Logs to STDOUT and also on log_file and broker log device

    class MultiDevice

      def initialize(*args)
        @streams = []
        if args.size == 0
          # No argument given, log to STDOUT
          @streams << STDOUT
        else
          args.each do |a|
            case a
            when String
              # This is a file path
              @streams << File.open(a, 'a+')
            else
              @streams << a
            end
          end
        end
      end

      def write(*args)
        @streams.each do |stream|
          stream.write(*args)
          stream.flush
        end
      end

      def close
        @streams.each &:close
      end

      def reopen
        @streams.each &:reopen
      end
    end
  end
end
