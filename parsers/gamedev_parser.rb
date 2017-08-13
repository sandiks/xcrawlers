require 'nokogiri'
require 'open-uri'
require 'parallel'
require_relative  '../helpers/helper'
require_relative  '../repo'
require_relative  '../cmd_helper'

class GDParser
  @@db = Repo.get_db

  def self.parse_categories

    url ="http://www.gamedev.ru/forum/"

    #page = Nokogiri::HTML(download_page(url))
    page = Nokogiri::HTML(File.open("all_forums.html"))

    cats = page.css("div#main_body div.list") #forums
    i=0
    cats.each do |cat|
      i+=1
      forums = cat.css("a").map { |ll| ll.text  }
      urls = cat.css("a").map { |ll| ll['href']  }

      #insert level0 forum
      forum0 = {fid:100*i,siteid:4,title:forums[0], level:0, name:urls[0].split('/')[3] }
      Repo.insert_or_update_forum(forum0,4)

      #insert sub forums
      j=0
      forums[1..-1].each do |forum|
        j+=1
        forum1 = {fid:100*i+j,siteid:4,title:forum, level:1,parent_fid:100*i, name:urls[j].split('?').last}
        Repo.insert_or_update_forum(forum1,4)
      end

    end
  end

  def self.check_forums(need_parse_threads=true)
    forums = @@db[:forums].filter(siteid:4,level:1).map(:fid)

    #forums.each do |fid|
    Parallel.each(forums,:in_threads=>3) do |fid|
      parse_forum(fid, need_parse_threads) if need_parse_forum(fid,4)
    end

  end

  def self.get_forum_name(fid)
    ff = @@db[:forums].where(siteid:4, fid:fid).first
    lev1 = ff[:name]
    pid = ff[:parent_fid]
    lev0 = @@db[:forums].where(siteid:4, fid:pid).first[:name]

    [lev0,lev1]
  end

  def self.parse_forum(fid, need_parse_threads=true)

    fname = get_forum_name(fid)

    p link = "http://www.gamedev.ru/#{fname[0]}/forum/?#{fname[1]}"

    page = Nokogiri::HTML(download_page(link))
    #page = Nokogiri::HTML(File.open("f_code_graphics.html"))

    #pages = (1..pmax).map { |pp|  "#{link}&page=#{pp}" }

    threads = page.css("div#main_body table.r tr")

    page_threads = threads.drop(1).map do |tr|
      {
        #url:  tr.css("td a")[0]['href'],
        fid:fid,
        tid:  tr.css("td a")[0]['href'].split("id=").last.to_i,
        title:tr.css("td a")[0].text,
        #maxp: tr.css("td:first a").map { |e| e.text.to_i  }.max,
        responses: tr.css("td")[3].text.to_i,
        updated: DateTime.strptime(tr.css("td")[4].text,"%d.%m.%y %H:%M"),
        siteid:4,
      }
    end

    Repo.insert_or_update_threads_for_forum(page_threads,4)

    #page_threads.each do |thr|
    Parallel.map(page_threads,:in_threads=>3) do |thr|

      tid = thr[:tid]

      page = Repo.calc_page(tid,thr[:responses],4)

      #thread_pages = @@db[:tpages].filter(siteid:4, tid:tid).map([:page,:postcount])
      #p "tid:#{tid} resps:#{thr[:responses]} last:#{last_page} page:#{page} thread:#{thread_pages}"

      parse_thread(fname[0],tid, page) if page>0

    end if need_parse_threads

  end


  def self.parse_thread(fname,tid, page=1)

    link = "http://www.gamedev.ru/#{fname}/forum/?id=#{tid}"
    link += "&page=#{page}" if page>1

    page_html = Nokogiri::HTML(download_page(link))
    #page_html = Nokogiri::HTML(File.open("thr1.html"))

    thread_posts = page_html.css("div#main_body div.mes")

    posts = thread_posts.map do|mes|

      time = Time.strptime(mes.css("table.mes td")[3].text,"%H:%M")
      date = parse_rudate(mes.css("table.mes td")[2].text, time)

      {
        siteid:4,
        mid:mes['id'].sub('m','').to_i,
        tid:tid,
        body: mes.css("> div.block").inner_html.encode('utf-8').strip,
        addeduid:mes.css("table.mes th a")[0]['href'].split('id=').last.to_i,
        addedby:mes.css("table.mes th a")[0].text.strip,
        addeddate: date
      }
    end


    users = posts.map { |pp| {siteid:4, uid:pp[:addeduid],name:pp[:addedby]}  }.uniq { |us| us[:uid] }

    Repo.insert_users(users,4)
    Repo.insert_posts(posts, tid, 4)
    Repo.insert_or_update_tpage(4,tid,page,posts.size)
    Repo.update_thread_bot_date(tid,4)

    p "inserted posts:#{posts.size} tid:#{tid} fid:#{fname}"
  end




  def self.parse_rudate(date,t)
    mru = %w[nil янв фев мар апр май июн июл авг сен окт ноя дек]

    dd = date.split(' ')
    mm_name = dd[1].chomp('.')
    if mru.include? mm_name

      d = dd[0].to_i
      m = mru.index(mm_name)
      y = dd[2].to_i
      #y = y > 90 ? 1900+y : 2000+y

    else
      date = get_moscow_datetime
      y,m,d = date.year , date.month , date.day
    end

    DateTime.new(y,m,d,t.hour,t.min,0,'+3')
  end

  def self.get_moscow_datetime
    DateTime.now.new_offset(3/24.0)
  end
end

def self.test_date
  p "thread time"
  p thread_time = DateTime.strptime("15.09.06 13:53","%d.%m.%y %H:%M")

  p "post time"
  time = Time.strptime("16:59","%H:%M")
  p date = GDParser.parse_rudate("11 янв. 2013", time)

end

#test_date

act=0

#GDParser.parse_categories if act==1

GDParser.check_forums if act==1
GDParser.parse_forum(405,false) if act==2
GDParser.parse_thread('code', 128490) if act==3
