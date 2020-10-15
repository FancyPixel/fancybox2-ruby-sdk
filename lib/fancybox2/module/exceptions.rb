module Fancybox2
  module Module
    module Exceptions

      class FbxfileNotProvided < StandardError
        def initialize(file_path, message = nil)
          message = message || "Fbxfile.example path not provided. Given: #{file_path}"
          super(message)
        end
      end

      class FbxfileNotFound < StandardError
        def initialize(file_path, message = nil)
          message = message || "Fbxfile.example not found at #{file_path}"
          super(message)
        end
      end

      class NotValidMQTTClient < StandardError
        def initialize(message = nil)
          message = message || 'The provided MQTT client is not an instance of PahoMqtt::Client'
          super(message)
        end
      end
    end
  end
end
