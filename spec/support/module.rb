RSpec.configure do |config|
  config.before :suite do
    # Replace some constants with mine
    Fancybox2::Module::Config.send(:remove_const, :FBXFILE_DEFAULT_FILE_PATH)
    Fancybox2::Module::Config::FBXFILE_DEFAULT_FILE_PATH = File.expand_path('../../../lib/fancybox2/module/Fbxfile', __FILE__)
  end
end
