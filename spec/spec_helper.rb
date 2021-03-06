require 'simplecov'
SimpleCov.start

$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'fancybox2'

Dir[File.expand_path('../support/**/*.rb', __FILE__)].each { |f| require f }

RSpec.configure do |config|
  $spec_log_file_path = "#{__dir__}/spec_log.txt"

  # Configure examples file
  # Uncomment if using --next-failure (or equivalent) rspec option
  # config.example_status_persistence_file_path = 'examples.txt'

  # Ensure no previous (zombie) mosquitto instance is still alive.
  # This can happen, for instance, when the test suite crashes due to a syntax error, and so Mosquitto.stop is not called
  Mosquitto.kill_zombies

  config.before(:suite) do
    # Do not start local mosquitto if a remote one gets used
    unless ENV['MOSQUITTO_HOST'] && ENV['MOSQUITTO_PORT']
      Mosquitto.start; sleep(0.5) # Give time to mosquitto to startup
    end
  end

  config.after(:suite) do
    unless Mosquitto.pid.nil?
      sleep(0.1) # Wait for late processes that are already connected to broker
      Mosquitto.stop
    end
  end

  config.before(:each) do
  end

  config.after(:each) do
    if File.exist?($spec_log_file_path)
      File.delete($spec_log_file_path)
    end
  end

  config.order = :random
end


## Some extension
RSpec::Matchers.define :have_attr_accessor do |field|
  match do |object_instance|
    object_instance.respond_to?(field) &&
        object_instance.respond_to?("#{field}=")
  end

  failure_message do |object_instance|
    "expected attr_accessor for '#{field}' on #{object_instance}"
  end

  failure_message_when_negated do |object_instance|
    "expected attr_accessor for '#{field}' not to be defined on #{object_instance}"
  end

  description do
    'checks to see if there is an attr accessor on the supplied object'
  end
end

RSpec::Matchers.define :have_attr_reader do |field|
  match do |object_instance|
    object_instance.respond_to?(field)
  end

  failure_message do |object_instance|
    "expected attr_reader for '#{field}' on #{object_instance}"
  end

  failure_message_when_negated do |object_instance|
    "expected attr_reader for '#{field}' not to be defined on #{object_instance}"
  end

  description do
    'checks to see if there is an attr reader on the supplied object'
  end
end

