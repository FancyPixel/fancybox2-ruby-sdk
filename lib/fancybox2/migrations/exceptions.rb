module Fancybox2
  module Migrations
    module Exceptions

      class FileNameError < StandardError
        def initialize(message = nil)
          message = message || 'One of the provided migrations file has an invalid name'
          super(message)
        end
      end
    end
  end
end