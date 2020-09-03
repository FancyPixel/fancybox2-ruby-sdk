class Mosquitto

  CONFIG_FILE_PATH = File.expand_path('../../config/mosquitto.conf', __FILE__)
  DEFAULT_PID_FILE_PATH = File.expand_path('../../tmp/mosquitto.pid', __FILE__)
  LISTENER_CONFIGS = {
      host: 'localhost',
      port: 2883
  }

  def self.delete_pid_file(pid_file_path = DEFAULT_PID_FILE_PATH)
    if File.exists?(pid_file_path)
      File.delete pid_file_path
    end
  end

  # :nocov:
  def self.kill_zombies(pid_file_path = DEFAULT_PID_FILE_PATH)
    if File.exists? pid_file_path
      pid = File.read(pid_file_path).to_i
      if pid > 0
        self.kill pid
      end
    end
  end
  # :nocov:

  def self.pid
    @pid
  end

  def self.pid=(pid)
    @pid = pid
  end

  def self.start(config_file_path = CONFIG_FILE_PATH)
    self.pid = Process.spawn "mosquitto -c #{config_file_path}", [:out, :err] => '/dev/null'
    Process.detach pid
    # Also write new PID on file
    self.write_pid_file
  end

  def self.stop(pid = self.pid)
    Process.kill('INT', pid) rescue nil
    self.delete_pid_file
  end

  # :nocov:
  def self.kill(pid = self.pid)
    Process.kill('KILL', pid) rescue nil
  end
  # :nocov:

  def self.write_pid_file(pid = self.pid, pid_file_path = DEFAULT_PID_FILE_PATH)
    file = File.open(pid_file_path, 'w+')
    file.write(pid)
    file.close
  end
end
