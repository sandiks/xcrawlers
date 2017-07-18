require_relative  '../repo'
require 'net/http'
require 'cgi'

act=2

def test1
  db = Repo.get_db
  forum = db[:forums].first(siteid:6, fid: 16)
  p forum[:bot_updated]
  p @updated = forum[:bot_updated]-10.0/3600
  #p posts = db[:posts].filter('siteid=? and addeddate > ?',6, @updated).order(:addeddate).all
  p db[:posts].first('siteid=? and mid =?',6, 19092100)[:addedby]

end
test1 if act ==1

UAGENT = "Mozilla/5.0 (Windows NT 10.0; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/47.0.2526.73 Safari/537.36"
COO = "ASP.NET_SessionId=x0dfwbu322wohrxpiactxoux; af_remember=a16695ff-7e2d-4d4a-8b7b-58102d49c426; af_data=lvdt=635969424136532787"


def get_hash(fid,tid)
  ticks = Time.now.to_i
  path = "http://www.sql.ru/forum/afservice.aspx?action=ph&qasw=#{ticks}&b=#{fid}&t=#{tid}"

  uri = URI(path)
  http = Net::HTTP.new(uri.host, 80)

  request = Net::HTTP::Get.new(uri.request_uri)
  request['Cookie'] = COO # <---
  res = http.request(request)
  res.body
end



def post(fid,tid,mid,title,text)

  path = "http://www.sql.ru/forum/actualpost.aspx?bid=#{fid}&tid=#{tid}&mid=#{mid}&p=1"
  uri = URI(path)
  http = Net::HTTP.new(uri.host, 80)

  request = Net::HTTP::Post.new(uri.request_uri)
  request['Cookie'] = COO
  request['User-Agent'] = UAGENT
  request['Referer'] = "http://www.sql.ru/forum/actualpost.aspx?bid=#{fid}&tid=#{tid}&mid=#{mid}&p=1"
  #request['content-type'] = "text/html; charset=windows-1251"

  hash = get_hash(fid,tid)
  post_data = "
tid=#{tid}
&bid=#{fid}
&mid=#{mid}
&act  
&hash=#{hash}
&p=1

&topicicon=0
&subject=#{title}
  
&message=#{text}
&post=Опубликовать"

  request.body = post_data.encode("windows-1251")
  res = http.request(request)
  puts res.code
end

def test2
  db = Repo.get_db

  #p get_hash(15,1211040)
  tid=1211121
  mid=19095151

  title ="Re: sd!!!"
  text="не открывается"

  if mid>0
    text_whom = db[:posts].first('siteid=? and mid =?',6, mid)[:addedby] rescue "nothing"
    text = "#{text_whom},

#{text}"
  end

  post(16,tid,mid,title,text) 

end
test2 if act==2
