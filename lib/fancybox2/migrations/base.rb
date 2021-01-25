module Fancybox2
  module Migrations
    class Base

      class << self
        def self.descendants
          ObjectSpace.each_object(Class).select { |klass| klass < self }
        end
      end

      attr_reader :name, :version

      def initialize(name)
        @name = name

        @version = Runner.extract_and_validate_version_from name
      end

      def call(up_or_down = :up)
        send up_or_down
      end
    end
  end
end
