module Fancybox2
  module Module
    class Base
      include Utils

      attr_accessor :logger

      def initialize(options = {})
        options.deep_symbolize_keys!
        @logger = options[:logger] || build_default_logger
      end
    end
  end
end