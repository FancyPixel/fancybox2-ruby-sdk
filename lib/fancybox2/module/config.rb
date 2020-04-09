module Fancybox2
  module Module
    class Config

      FBXFILE_DEFAULT_FILE_PATH = File.expand_path('../Fbxfile', $0)
      FBXFILE_EXAMPLE_FILE_PATH = File.expand_path('../config/Fbxfile.example', __FILE__)

      DEFAULT_TOPIC_FORMAT = 'modules/%s/%s'
    end
  end
end
