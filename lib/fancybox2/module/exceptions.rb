module Fancybox2
  module Module
    module Exceptions

      class FbxfileNotFound < StandardError
        def initialize(file_path, message = nil)
          message = message || "Fbxfile not found at #{file_path}"
          super(message)
        end
      end

      class NotValidMQTTClient < StandardError
        def initialize(message = nil)
          message = message || 'The provided MQTT client is not an instance of PahoMqtt::Client'
          super(message)
        end
      end

      class NotAValidSubscription < StandardError
        def initialize(topic, message = nil)
          message = message || "The subscription topic #{topic} is not valid"
          super(message)
        end
      end
    end
  end
end
