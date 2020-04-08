module Fancybox2
  module Module
    module Exceptions

      class FbxfileNotFound < StandardError
        def initialize(file_path, message = nil)
          message = message || "Fbxfile not found at #{file_path}"
          super(message)
        end
      end
    end
  end
end
