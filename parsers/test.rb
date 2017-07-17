require 'net/https'

string = 'Norrlandsvägen'
p string.encode('iso-8859-1')
p string.encode('utf-8')

def test1
  uri = URI.parse("https://bitcointalk.org/index.php?topic=2006833.20")
  options = {
    :use_ssl => uri.scheme == 'https',
    :verify_mode => OpenSSL::SSL::VERIFY_NONE
  }
  
  response = Net::HTTP.start(uri.host, uri.port, options) do |https|
    https.request(Net::HTTP::Get.new(uri))
  end

  #body = response.body.force_encoding('ISO-8859-1').encode('UTF-8')

  body = response.body.force_encoding('ISO-8859-1')
  File.write("res.html", body)
end
test1
