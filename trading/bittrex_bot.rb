require "rest-client"
require "colorize"
require "json"
require 'rufus-scheduler'


BASE_URL = "https://bittrex.com/api/v1.1/"
API_KEY = "<YOUR_API_KEY>"
API_SECRET = "<YOUR_API_SECRET>"

@units_bought = 0
@currency = ARGV[0]
@market_name = "BTC-"+ (@currency||"ETH")

BOT_TYPE = ARGV[1].to_i

URIs = {
        :public => {
          :markets => "public/getmarkets",
          :currencies => "public/getcurrencies",
          :market_ticker => "public/getticker?market=%s",
          :market_day_summaries => "public/getmarketsummaries",
          :market_day_summary => "public/getmarketsummary?market=%s",
          :order_book => "public/getorderbook?market=%s&type=%s",
          :last_trades => "public/getmarkethistory?market=%s",
        },
        :account => {
          :balance => "account/getbalances",
          :currency_balance => "account/getbalance?currency=%s",
          :deposit_address => "account/getdepositaddress?currency=%s",
          :withdraw => "account/withdraw?currency=%s&quantity=%s&address=%s",    
          :get_order_by_uuid => "account/getorder&uuid=%s",
          :orders_history => "account/getorderhistory",
          :market_orders_history => "account/getorderhistory?market=%s",
          :withdrawal_history => "account/getwithdrawalhistory?currency=%s",
          :deposit_history => "account/getwithdrawalhistory?currency=%s"
        },
        :market => {
          :buy => "market/buylimit?market=%s&quantity=%s&rate=%s",
          :sell => "market/selllimit?market=%s&quantity=%s&rate=%s",
          :cancel_by_uuid => "market/cancel?uuid=%s",
          :open_orders => "market/getopenorders?market=%s"
        }
      }

def hmac_sha256(msg, key)
  digest = OpenSSL::Digest.new("sha512")
  OpenSSL::HMAC.hexdigest(digest, key, msg)
end

def get_url(params)
  url = BASE_URL + URIs[params[:api_type].to_sym][params[:action].to_sym]
  case params[:action]
  when "buy"
    url = sprintf(url, params[:market], params[:quantity], params[:rate])
  when "sell"
    url = sprintf(url, params[:market], params[:quantity], params[:rate])
  when "cancel_by_uuid"
    url = sprintf(url, params[:uuid])
  when "open_orders", "getticker", "market_day_summary", "last_trades", "market_orders_history"
    url = sprintf(url, params[:market])
  when "currency_balance", "deposit_address"
    url = sprintf(url, params[:currency])
  when "order_book"
    url = sprintf(url, params[:market], params[:order_type])
  end
  nonce = Time.now.to_i.to_s
  url = url + "&apikey=#{API_KEY}&nonce=#{nonce}" if ["market", "account"].include? params[:api_type]
  return url
end

def call_api(url)
  response = RestClient.get(url)
  parsed_body = JSON.parse(response.body)
  puts "Fetching ..."
  puts (parsed_body["success"] ? "Success" : "Failed")
  parsed_body["result"] if parsed_body["success"]
end

def call_secret_api(url)
  sign = hmac_sha256(url, API_SECRET)
  response = RestClient.get(url, {:apisign => sign})
  puts "Calling API...".yellow
  parsed_body = JSON.parse(response.body)
  p [url, parsed_body]
  puts (parsed_body["success"] ? "Success".green : "Failed".red)
  parsed_body["result"] if parsed_body["success"]
end

def get_order_book(market_name, order_type="both")
  url = get_url({api_type: "public", action: "order_book", market: market_name, order_type:order_type})
  orders = call_api(url)
  #orders.map { |oo| oo["Quantity"]  }
end

def get_last_trades(market_name)
  url = get_url({api_type: "public", action: "last_trades", market: market_name})
  p "#{url}"
  orders = call_api(url)
 
end


@sell_ords_store = {}
@bid_ords_data = {}
def parse_orders(crypto_sym="ETH")
  mname = "BTC-#{crypto_sym}"
  date = DateTime.now.new_offset(3/24.0).strftime("%F %k:%M:%S ")

  p "-------"
  p " PARSE #{mname} date: #{date}"
  
  all_ords = get_order_book(mname,"both")

  sell_ords_arr = all_ords["sell"]
  buy_ords_arr = all_ords["buy"]
  
  sell_ords = Hash[sell_ords_arr.map { |ord| [ ord["Rate"],ord["Quantity"] ]}]
  buy_ords = Hash[buy_ords_arr.map { |ord| [ ord["Rate"],ord["Quantity"] ]}]
   
  buyed={}
  @sell_ords_store.each do |kk,vv|
    if !sell_ords.key?(kk)
     buyed[kk]=vv
    end
  end
  @sell_ords_store = sell_ords
  #dd = buyed.map { |kk,vv| "sum:#{'%.4f' % (kk*vv)} rate:#{'%.4f' % kk} q:#{'%.4f' % vv}"}
  dd = buyed.map { |kk,vv| kk*vv}.reduce(:+)||0
  p "buyed count:#{buyed.size} sum:#{'%.4f' % dd}"
  


  bidded={}
  @bid_ords_data.each do |kk,vv|
    if !buy_ords.key?(kk)
     bidded[kk]=vv
    end
  end
  @bid_ords_data = buy_ords
  #dd = bidded.map { |kk,vv| "sum:#{'%.4f' % (kk*vv)} rate:#{'%.4f' % kk} q:#{'%.4f' % vv}"}
  dd = bidded.map { |kk,vv| kk*vv}.reduce(:+)||0
  p "bidded count:#{bidded.size} sum:#{'%.4f' % dd}"
  

end


def analaz(period=90)
  p "task:shedule-bittrex"
  scheduler = Rufus::Scheduler.new
  scheduler.every "#{period}s" do
    parse_orders("ETH")
  end
  scheduler.join  
end

def show_bought_orders
   dd= get_last_trades("BTC-ETH").select{|ord| ord["OrderType"]=="BUY"}
   .map { |ord| {Date: DateTime.parse(ord["TimeStamp"]), Total: ord["Total"], Type:"BUY"}  }

   puts dd.group_by{|pp| dd=pp[:Date]; DateTime.new(dd.year,dd.month,dd.day,dd.hour,dd.minute) }
   .map { |k,vv| "date:#{k.strftime("%F %k:%M")} count:#{vv.size} sum:#{'%.4f' %  vv.reduce(0) { |sum,x| sum + x[:Total] }} BUY"  }
 end

case 3
when 1; parse_orders
when 2; analaz(20)
when 3; show_bought_orders
end