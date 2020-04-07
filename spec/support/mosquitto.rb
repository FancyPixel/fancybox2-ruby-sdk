class Mosquitto

  CONFIG_FILE_PATH = File.expand_path('../../config/mosquitto.conf', __FILE__)

  def self.pid
    @pid
  end

  def self.pid=(pid)
    @pid = pid
  end

  def self.start(config_file_path = CONFIG_FILE_PATH)
    self.pid = spawn "mosquitto -c #{config_file_path} > /dev/null 2>&1 &"
  end

  def self.stop(pid = self.pid)
    Process.kill 'INT', pid
  end

  def self.kill(pid = self.pid)
    Process.kill 'KILL', pid
  end
end
