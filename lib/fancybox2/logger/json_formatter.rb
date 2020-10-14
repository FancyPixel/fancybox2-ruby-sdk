require 'logger'
require 'json'

module Fancybox2
  module Logger
    class JSONFormatter < ::Logger::Formatter
      def call(severity, time, progname, msg)
        json = JSON.generate(
            level: severity,
            timestamp: time.utc.strftime('%Y-%m-%dT%H:%M:%S.%3NZ'.freeze),
            #progname: progname,
            message: msg,
            pid: Process.pid
        )
        "#{json}\n"
      end
    end
  end
end
