require 'paho-mqtt'

module Fancybox2
  module Logger
    class MQTTLogDevice

      attr_accessor :client, :client_params
      attr_reader :internal_client

      def initialize(*args)
        options = args.extract_options.deep_symbolize_keys
        @client_params = options[:client_params]
        @client = options[:client] || create_client
        # Connect the client if it's created and handled by us
        @client.connect if @internal_client
      end

      private

      def create_client
        client = PahoMqtt::Client.new host: @client_params[:host] || 'localhost',
                                      port: client_port,
                                      client_id: @client_params[:client_id],
                                      username: @client_params[:username],
                                      password: @client_params[:password]

        # In order to not override client's defaults, set these client params only if they've been provided by user (not nil)
        client.mqtt_version = @client_params[:mqtt_version] if @client_params[:mqtt_version]
        client.clean_session = @client_params[:clean_session] if @client_params[:clean_session]
        client.persistent = @client_params[:persistent] if @client_params[:persistent]
        client.reconnect_limit = @client_params[:reconnect_limit] if @client_params[:reconnect_limit]
        client.reconnect_delay = @client_params[:reconnect_delay] if @client_params[:reconnect_delay]
        client.ssl = @client_params[:ssl] if @client_params[:ssl]
        @internal_client = true
      end

      def client_port
        if @client_params[:port]
          @client_params[:port]
        elsif @client_params[:ssl]
          8883
        else
          1888
        end
      end
    end
  end
end
