require 'nokogiri'

def detect_quote_to(text)


  ptext = Nokogiri::HTML.fragment(text)

  ptext.css('div.quoteheader').each do |el|
    href=el.css("a")[0]['href'] 
    th_m = href.split("topic=").last.scan(/\d+/)
    nnode = "[q #{th_m[0]}.#{th_m[1]}]" 
    el.replace nnode
  
  end 
  
  #ptext.css("div.quoteheader").remove
  ptext.css("div.quote").remove

  #node.remove
  html= ptext.to_html
  p html
end

text = %q{
<div class="quoteheader"><a href="https://bitcointalk.org/index.php?topic=202754.msg20922884#msg20922884">Quote from: profit59 on <b>Today</b> at 11:25:38 AM</a></div><div class="quote"><div class="quoteheader"><a href="https://bitcointalk.org/index.php?topic=2027544.msg20922885#msg20922885">Quote from: profit59 on <b>Today</b> at 11:25:38 AM</a></div><div class="quote">зачем выносить на всеобщее обозрение перспективные форки? пусть каждый своей головой доходит<br></div>зачем выносить на всеобщее обозрение перспективные форки? пусть каждый своей головой доходит<br></div>aaaaaaaaaaaaaaaaaa}
detect_quote_to(text)

