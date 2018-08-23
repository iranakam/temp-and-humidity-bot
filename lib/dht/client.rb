require 'faraday'
require 'json'

module DHT
  class Client
    def initialize
      @client = Faraday.new(url: 'https://n-homebot.tk') do |faraday|
        faraday.request :url_encoded
        faraday.response :logger
        faraday.adapter Faraday.default_adapter
      end
    end

    def temp_and_humidity
      res = @client.get do |req|
        req.url '/api/dht'
        req.headers['Content-Type'] = 'application/json'
      end
      JSON.parse res.body
    end
  end
end
