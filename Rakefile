require 'sinatra/activerecord'
require 'sinatra/activerecord/rake'
require './lib/dht/client'
require 'line/bot'
require './models/user'

ActiveRecord::Base.configurations = YAML.load_file('config/database.yml')
ActiveRecord::Base.establish_connection(ENV['RACK_ENV'].to_sym)

namespace :bot do
  top_level = self
  using Module.new {
    refine(top_level.singleton_class) do
      def client
        Line::Bot::Client.new do |config|
          config.channel_secret = ENV['LINE_CHANNEL_SECRET']
          config.channel_token = ENV['LINE_CHANNEL_TOKEN']
          Time.zone = ENV['TZ']
        end
      end

      def temp_and_humidity
        @temp_and_humidity ||= DHT::Client.new.temp_and_humidity
      end

      def temperature
        temp_and_humidity['temperature']
      end

      def humidity
        temp_and_humidity['humidity']
      end
    end
  }

  desc 'multicast temperature and humidity'
  task :multicast_temperature_and_humidity do
    to = User.pluck(:line_user_id)
    messages = [{
      type: 'text',
      text: "現在の室温は#{temperature.floor(1)}°C、湿度は#{humidity.floor(1)}%です。(#{DateTime.now.in_time_zone.strftime('%Y/%m/%d %H:%M')})"
    }]
    client.multicast(to, messages)
  end
end
