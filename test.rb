require 'paho-mqtt'

client = PahoMqtt::Client.new host: 'localhost'
client.connect

threads = []
100.times do |n|
  threads << Thread.new do
    10000.times do |m|
      client.publish 'the_topic', "Message #{m} from thread #{n}"
      # sleep rand(0.0001..0.0002)
    end
  end
end

sleep 5
threads.each &:join
client.disconnect
