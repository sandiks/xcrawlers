require "rest-client"
require "colorize"
require "json"
require 'rufus-scheduler'


BASE_URL = "https://www.coinexchange.io/api/v1/"
API_KEY = "<YOUR_API_KEY>"
API_SECRET = "<YOUR_API_SECRET>"

def call_api(url)
  response = RestClient.get(url)
  parsed_body = JSON.parse(response.body)
  puts "Fetching ..."
  is_successed = parsed_body["success"]=="1" 
  puts (is_successed ? "Success" : "Failed")
  parsed_body["result"] if is_successed
end


def get_order_book(mid=1)
  #https://www.coinexchange.io/api/v1/getorderbook?market_id=1
  url = "#{BASE_URL}getorderbook?market_id=#{mid}"
  orders = call_api(url)
  
end

def get_last_trades(market_name)
  url = get_url({api_type: "public", action: "last_trades", market: market_name})
  p "#{url}"
  orders = call_api(url)
 
end


@sell_ords_store = {}
@bid_ords_data = {}
def parse_orders(crypto_sym="ETH")

  date = DateTime.now.new_offset(3/24.0).strftime("%F %k:%M:%S ")

  p "-------"
  p " PARSE date: #{date}"
  p all_ords = get_order_book(18)["SellOrders"]
  

end


def analaz(period=90)
  p "task:shedule-bittrex"
  scheduler = Rufus::Scheduler.new
  scheduler.every "#{period}s" do
    parse_orders("ETH")
  end
  scheduler.join  
end

case 1
when 1; parse_orders
when 2; analaz(20)
when 3; show_bought_orders
end