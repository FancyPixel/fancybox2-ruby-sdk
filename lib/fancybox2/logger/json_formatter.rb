require 'logger'
require 'json'

module Fancybox2
  module Logger
    class JSONFormatter < ::Logger::Formatter
      def call(severity, time, progname, msg)
        json = JSON.generate(
            severity: severity,
            time: format_datetime(time),
            progname: progname,
            message: msg,
            pid: Process.pid
        )
        "#{json}\n"
      end
    end
  end
end
