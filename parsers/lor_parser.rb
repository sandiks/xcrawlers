require 'nokogiri'
require 'open-uri'
require 'parallel'
require_relative  '../helpers/helper'
require_relative  '../repo'
require_relative  '../cmd_helper'



class LORParser
  DB = Repo.get_db
  SID=3

  def self.parse_categories

    url ="http://www.linux.org.ru/forum/"

    #page = Nokogiri::HTML(download_page(url))
    page = Nokogiri::HTML(File.open("allforums.html"))

    cats = page.css("div#bd  ul:first li") #forums
    i=0
    cats.each do |cat|
      i+=1
      forums = cat.css("a").map { |ll| ll.text  }
      urls = cat.css("a").map { |ll| ll['href']  }

      #insert level0 forum
      p forum0 = {fid:10*i,siteid:3,title:forums[0], level:1, name:urls[0].split('/')[2] }
      Repo.insert_or_update_forum(forum0,3)

    end
  end

  def self.check_forums(parse_threads=false)
    all = DB[:forums].filter(siteid:3,check:1).map(:fid)

    Parallel.each(all,:in_threads=>2) do |fid|
    #all.each do |fid|
      parse_forum(fid,1,parse_threads) if need_parse_forum(fid,3)

    end

  end

  def self.parse_forum(fid, pg=1, need_parse_threads=false)

    fname = Repo.get_forum_name(fid,3)
    page_link = (pg==1 ? "" : "/?offset=#{(pg-1)*30}")

    p link = "https://www.linux.org.ru/forum/#{fname}#{page_link}"


    page_noko = Nokogiri::HTML(download_page(link), nil, 'utf-8')
    #page = Nokogiri::HTML(File.open("f20.html"), nil, 'utf-8')

    #pmax = page_noko.css("div#main_body p:first b a").map { |e| e.text.to_i  }.max
    #pmax=1 if pmax==0

    threads = page_noko.css("table.message-table tbody tr")

    i=0

    page_threads = threads.map do |tr|

      begin
        i+=1
        thr={
          #url:  tr.css("td a")[0]['href'],
          fid:fid,
          tid:  tr.css("td:first a")[0]['href'].split("/").last.split("?").first.to_i,
          title:tr.css("td:first a:first > text()").text.strip,
          updated: DateTime.parse(tr.css("td.dateinterval > time")[0]['datetime']),
          responses: tr.css("td:nth-child(3)").text.strip.to_i,
          siteid:SID,
        }
      rescue =>ex
        p "[error] #{ex.class} title:#{title}"
      end
    end

    #page_threads.each_with_index { |tt, ind| p  "#{ind} #{tt[:title]} || #{tt[:updated]}"  }

    Repo.insert_or_update_threads_for_forum(page_threads,3)
    Repo.update_forum_bot_date(fid,3)


    #page_threads.each do |thr|
    Parallel.map(page_threads,:in_threads=>2) do |thr|
      tid = thr[:tid]

      #next if not tid==10856785

      page = Repo.calc_page(tid,thr[:responses],3)

      thread_pages = DB[:tpages].filter(siteid:3, tid:tid).map([:page,:postcount])
      resps = thr[:responses]

      inserted =parse_thread(fname,tid, page) if page>0
      p "tid:#{tid} resps:#{resps} page:#{page} inserted:#{inserted} thread:#{thread_pages}"


    end if need_parse_threads

  end


  def self.parse_thread(fname, tid, page=1)

    fname = Repo.get_forum_name_by_tid(tid,3) if fname.nil?
    return if fname.nil? || page==0

    link = "https://www.linux.org.ru/forum/#{fname}/#{tid}"
    link += "/page#{page-1}" if page>1

    page_html = Nokogiri::HTML(download_page(link), nil, 'utf-8')
    #page = Nokogiri::HTML(File.open("thr1.html"), nil, 'utf-8')


    parse_first_mes(tid,page_html.css('div.msg-container div.msg_body')) if page==1

    #comments
    thread_posts = page_html.css("div.comment article")

    posts = thread_posts.map do|mes|

      post_html = mes.css('div.msg-container  div.msg_body.message-w-userpic')

      addedby = post_html.xpath('div[1]/a/@href')
      addedby = addedby.map {|attr| attr.value.split('/')[2]}.first

      #addedby = post_html.css("div.sign a")[0]['href'].split('/')[2]
      time = post_html.css('> div.sign > time')[0]['datetime']

      post_html.search('div.sign').remove
      post_html.search('div.reply').remove

      {
        siteid:3,
        mid:mes['id'].split('-').last.to_i,
        tid:tid,
        body: post_html.inner_html.strip,
        addedby: addedby,#mes.css('div.msg-container  div.msg_body > div.sign a')[0]['href'].split('/')[2],
        addeddate: DateTime.parse(time)
      }
    end

    # insert to database
    users = posts.map { |pp| {siteid:3, uid:pp[:addeduid],name:pp[:addedby]}  }.uniq { |us| us[:name] }
    inserted_users=0 #Repo.insert_users(users)

    inserted = Repo.insert_posts(posts, tid,3)
    Repo.insert_or_update_tpage(3,tid, page, posts.size)
    Repo.update_thread_bot_date(tid,3)

    inserted
  end


  def self.parse_first_mes(tid, first_post)

    post_html = first_post.css('div:nth-child(1)')

    #p addedby = first_post.css("div.sign a")[0]['href'].split('/')[2]
    addedby = first_post.xpath('footer/div[2]/a/@href')
    addedby = addedby.map {|attr| attr.value.split('/')[2]}.first

    time = first_post.css('footer div.sign > time')[0]['datetime']

    first = {
      siteid:3,
      mid:tid,
      tid:tid,
      body: post_html.inner_html.strip,
      addedby: addedby,
      addeddate: DateTime.parse(time),
      first:1
    }

    Repo.insert_posts([first], tid,3)
  end

end


#LORParser.parse_forum(20,2,false)
#LORParser.check_forums
