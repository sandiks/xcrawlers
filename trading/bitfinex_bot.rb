require "rest-client"
require "colorize"
require "json"
require 'rufus-scheduler'


BASE_URL = "https://api.bitfinex.com/v2/"
API_KEY = "<YOUR_API_KEY>"
API_SECRET = "<YOUR_API_SECRET>"

def call_api(url)
  response = RestClient.get(url)
  parsed_body = JSON.parse(response.body)
  puts "Fetching ..."
  parsed_body
end

#https://api.bitfinex.com/v2/tickers?symbols=tBTCUSD,tETHUSD
#https://api.bitfinex.com/v2/trades/tETHUSD/hist
#https://api.bitfinex.com/v2/candles/trade:1m:tBTCUSD/last

#tETHUSD tBTCUSD

def get_order_book(mid=1)
  
  url = "#{BASE_URL}trades/tETHUSD/hist"
  orders = call_api(url)
  orders.map { |rr| p rr   }
end

get_order_book
