require 'line/bot'
require 'sinatra/base'
require 'sinatra/activerecord'
require './models/user'
require './lib/dht/client'

ActiveRecord::Base.configurations = YAML.load_file('config/database.yml')
ActiveRecord::Base.establish_connection(ENV['RACK_ENV'].to_sym)

class Application < Sinatra::Base
  before do
    @client ||= Line::Bot::Client.new do |config|
      config.channel_secret = ENV['LINE_CHANNEL_SECRET']
      config.channel_token = ENV['LINE_CHANNEL_TOKEN']
    end
  end

  post '/callback' do
    body = request.body.read
    signature = request.env['HTTP_X_LINE_SIGNATURE']

    unless @client.validate_signature(body, signature)
      error 400 do
        'Bad Request'
      end
    end

    events = @client.parse_events_from(body)

    events.each do |event|
      handle_event(event)
    end
    'OK'
  end

  not_found do
    error 400 do
      'Not Found'
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

  def handle_event(event)
    case event['type']
    when 'follow'
      handle_follow(event)
    when 'unfollow'
      handle_unfollow(event)
    when 'message'
      handle_follow(event)
      handle_message(event)
    end
  end

  def handle_follow(event)
    if (u = User.find_by(line_user_id: event['source']['userId']))
      u.is_blocked = false
      u.save
    else
      User.new(line_user_id: event['source']['userId']).save
    end
  end

  def handle_unfollow(event)
    return unless (u = User.find_by(line_user_id: event['source']['userId']))
    u.is_blocked = true
    u.save
  end

  def handle_message(event)
    handle_follow(event) unless User.exists?(line_user_id: event['source']['userId'])
    return unless event.type == Line::Bot::Event::MessageType::Text
    reply_text(event, handle_text(event.message['text']))
  end

  def handle_text(text)
    case text
    when /.*(気温|室温).*/
      "現在の室温は#{temperature.floor(1)}°Cです。"
    when /.*(湿度).*/
      "現在の湿度は#{humidity.floor(1)}%です。"
    else
      '「室温は？」や「湿度は？」など、知りたい情報を入力してください。'
    end
  end

  def reply_text(event, text)
    @client.reply_message(event['replyToken'], type: 'text', text: text)
  end
end
