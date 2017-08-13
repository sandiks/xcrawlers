require 'nokogiri'
require 'open-uri'
require 'parallel'
require_relative  '../../repo'


class ONLN_search

  def self.search_user_posts(uid, fr,to)

    url = "http://forum.onliner.by/search.php?type=uposts&id=#{uid}"
    links =[]
    (fr..to).each do |p|
      start = 20*p
      links<< "#{url}&start=#{start}"
    end

    Parallel.map(links,:in_threads=>4) do |link|
      parse_search_page_by_user(link)
    end
  end

  def self.parse_search_page_by_user(url, page=1)

    p link = url
    #link += "&page=#{page}" if page>1
    headers = { 'User-Agent' => 'Mozilla/5.0 (Windows NT 6.3; rv:36.0) Gecko/20100101 Firefox/36.0',
                "Cookie" => "onl_session=AxrE7rhkbTxzbOJhYzngIOR%2BoLLRpwbv8Wdos%2BL7fqaAwa7756bZgGdN16puEFFHH9wH5huH6bTNhN9ZCJjuX%2BlxD4c7F3xwgNQljVxG%2BI71XcF2gtHx38WvzpghaqH9ts%2FDxs%2B8fpSllbU0zXhINYGRGlnACxiqvxmciXTa3GuJEpGwIX0NKHo6BjEEGs6i5ICHlhI5HnZrsZMNooqeuqKPXyE9w6ybiAbL4P%2FqeArZkgF2IPuO7%2BHDJ8N%2BHHOF%2BnPSJZyswPc%3D  "
                }
    page_html = open(link,headers)
    #File.write('out.html',page_html.read ); return

    page_noko = Nokogiri::HTML(page_html)
    #page_noko = Nokogiri::HTML(File.open("search1.htm"))

    thread_posts = page_noko.css("ul.b-messages-thread li.msgpost")

    posts=[]
    threads=[]
    forums=[]

    thread_posts.each_with_index do|mes,indx|

      forum_url =mes.css("div.msgpost-txt-i div:first a")[0]
      forum_title = forum_url.text
      fid = forum_url['href'].scan(/\d+/).first.to_i
      forums<< {fid:fid,siteid:5,title:forum_title, level:1 }

      thread_url =mes.css("div.msgpost-txt-i div:first a")[1]
      thr_title = thread_url.text
      tid = thread_url['href'].scan(/\d+/).first.to_i
      threads<< {
        fid: fid,
        tid: tid,
        title:thr_title,
        siteid:5,
      }

      date_str =mes.css("div.b-msgpost-txt small.msgpost-date").text
      date = DateTime.strptime(date_str,"%d.%m.%Y %H:%M")

      body_html = mes.css("div.b-msgpost-txt div.content")
      body = body_html.inner_html.strip

      mid = body_html[0]['id'].sub('message_','').to_i

      addeduid = mes.css("div.b-mtauthor-i div.b-mta-card")[0]['data-user-id'].to_i
      addedby = mes.css("div.b-mtauthor-i big.mtauthor-nickname a")[0].text

      posts<< {
        siteid:5,
        mid:mid,
        tid:tid,
        body: body,
        addeduid:addeduid,
        addedby:addedby,
        addeddate:date,
      }


    end

    forums.uniq! { |ff| ff[:fid] }
    threads.uniq! { |tt| tt[:tid] }

    Repo.insert_forums(forums,5)
    Repo.insert_threads(threads,5)

    #forums.map { |pp| p pp[:siteid]  }
    uniq_threads_id = threads.map { |pp| pp[:tid]  }
    users = posts.map { |pp| {siteid:5, uid:pp[:addeduid],name:pp[:addedby]}  }.uniq { |us| us[:uid] }

    Repo.insert_users(users,5)
    Repo.insert_posts(posts, uniq_threads_id, 5)

    p "inserted posts:#{posts.size}"
  end

end

def test_date

  #p thread_time = DateTime.strptime("07.09.2015 14:06","%d.%m.%Y %H:%M")

  rr = /\d+/
  '/topic.php?t=10066513&p=83093740'.scan(rr)[0]

end

act=3

#589693
ONLN_parser.search_user_posts(589693,211,310) if act==1

