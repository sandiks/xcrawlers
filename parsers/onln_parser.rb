require 'nokogiri'
require 'open-uri'
require 'parallel'
require_relative  '../repo'


class ONLN_parser

  DB = Repo.get_db

  def self.parse_categories

  end

  def self.check_forums(need_parse_threads=true)

  end

  def self.parse_forum(fid, need_parse_threads=true)

    p link="http://forum.onliner.by/viewforum.php?f=#{fid}"
    page_html = downl(link)

    page_noko = Nokogiri::HTML(page_html)
    topics = page_noko.css("ul.b-list-topics li")

    threads=[]

    topics.each_with_index do|tt,indx|

      title_html =tt.css('div.b-lt-subj > h3 > a:first')[0]

      tid = title_html['href'].scan(/\d+/)[0].to_i
      thr_title = title_html.text

      updated_str =tt.css('div.b-lt-author  > a.link-getlast')[0]['title']
      upd_date = DateTime.strptime(change_rudate(updated_str),"%d.%m.%Y %H:%M")

      respns = tt.css('strong.total-msg').text.to_i
      last = Repo.calc_last_page(respns+1,20)

      threads<< {
        fid: fid,
        tid: tid,
        title:thr_title,
        responses:respns,
        updated:upd_date,
        siteid:5,
      }
    end

    Repo.insert_or_update_threads_for_forum(threads,5)

    Parallel.map(threads,:in_threads=>4) do |thr|
    #threads.each do |thr|

      tid = thr[:tid]

      page = Repo.calc_page(tid,thr[:responses]+1,5)

      thread_pages = DB[:tpages].filter(siteid:5, tid:tid).map([:page,:postcount])
      p "tid:#{tid} resps:#{thr[:responses]}  page:#{page} thread:#{thread_pages}"

      if page>0

        if need_parse_threads
          start=(page-1)*20
          p link="http://forum.onliner.by/viewtopic.php?t=#{tid}&start=#{start}"
          parse_thread_page(link)
        end

      else
        #p "no changes tid:#{tid} respns:#{thr[:responses]}"
      end
    end
    p "inserted threads :#{threads.size} fid:#{fid}"

  end

  def self.downl(link)
    headers = { 'User-Agent' => 'Mozilla/5.0 (Windows NT 6.3; rv:36.0) Gecko/20100101 Firefox/36.0',
                "Cookie" => "onl_session=AxrE7rhkbTxzbOJhYzngIOR%2BoLLRpwbv8Wdos%2BL7fqaAwa7756bZgGdN16puEFFHH9wH5huH6bTNhN9ZCJjuX%2BlxD4c7F3xwgNQljVxG%2BI71XcF2gtHx38WvzpghaqH9ts%2FDxs%2B8fpSllbU0zXhINYGRGlnACxiqvxmciXTa3GuJEpGwIX0NKHo6BjEEGs6i5ICHlhI5HnZrsZMNooqeuqKPXyE9w6ybiAbL4P%2FqeArZkgF2IPuO7%2BHDJ8N%2BHHOF%2BnPSJZyswPc%3D  "
                }
    page_html = open(link,headers)

  end


  def self.parse_thread_page(url)

    link = url
    tid = url.scan(/\d+/)[0].to_i
    pp = url.scan(/\d+/)[1].to_i/20+1

    page_html = downl(link)

    page_noko = Nokogiri::HTML(page_html)
    thread_posts = page_noko.css("ul.b-messages-thread li.msgpost:not(.msgfirst)")

    posts=[]

    thread_posts.each_with_index do|mes,indx|
      date_str =mes.css("div.b-msgpost-txt small.msgpost-date > span:first").text
      date=nil
      begin
        date = DateTime.strptime(change_rudate(date_str),"%d.%m.%Y %H:%M")
      rescue => ex
        puts "#{ex.class} #{change_rudate(date_str)}"
      end
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
    #Repo.insert_users(users,5)
    Repo.insert_posts(posts, tid, 5)
    Repo.insert_or_update_tpage(5,tid,pp,posts.size)
    Repo.update_thread_bot_date(tid,5)

    #p "inserted posts:#{posts.size}"

  end

  def self.change_rudate(date)
    mru = %w[nil янв фев мар апр мая июн июл авг сен окт ноя дек]

    dd = date.split(' ')
    dd[1] = dd[1][0..2]
    mindx = mru.index(dd[1])
    "#{dd[0]}.#{mindx}.#{dd[2]} #{dd[3]}"

    #DateTime.new(y,m,d,t.hour,t.min,0,'+3')
  end

end

act=0

ONLN_parser.parse_forum(64,false) if act==2

url="http://forum.onliner.by/viewtopic.php?t=15890919&start=11840"
ONLN_parser.parse_thread_page(url) if act==3
