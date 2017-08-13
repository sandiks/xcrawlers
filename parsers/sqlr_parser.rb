require 'nokogiri'
require 'open-uri'
require 'parallel'
require_relative  '../helpers/helper'
require_relative  '../helpers/sqlr_helper'
require_relative  '../repo'
require_relative  '../cmd_helper'

class SqlrParser

  DB = Repo.get_db
  SID = 6

  def self.downl(link)
    download_page(link,true) #use tor
  end

  def self.list_forums

    link ="http://www.sql.ru/forum"

    page = Nokogiri::HTML(downl(link))
    #page = Nokogiri::HTML(File.open("allforums.html"))

    cats = page.css("table.forumTable tr") #forums

    cats.each do |cat|
      if cat.css("td").size == 6
        flink = cat.css("td:nth-child(2) a:first")[0]['href']
        ftitle = cat.css("td:nth-child(2) a:first").text
        fcode = flink.split('/').last

        fid = SqlrHelper.get_forum_id(fcode)
        if fid!=-1
          forum = {fid:fid, siteid:SID, title:ftitle, level:1, name:fcode }
          Repo.insert_or_update_forum(fid,SID)

        end
      end
      #p forum0 = {fid:10*i,siteid:SID, title:forums[0], level:1, name:urls[0].split('/')[2] }
      #Repo.insert_or_update_forum(forum0,3)

    end
  end

  def self.check_forums(need_parse_threads=false)

    forums = DB[:forums].filter(siteid:SID,check: 1).all

    Parallel.map(forums,:in_threads=>2) do |ff|
      #forums.each do |ff|
      parse_forum(ff[:fid], need_parse_threads) if need_parse_forum(ff[:fid],SID)
    end
  end

  def self.parse_forum(fid, need_parse_threads=false, parse_thread_number=50)

    #fid = SqlrHelper.get_forum_id(fname)
    fname = Repo.get_forum_name(fid,SID)
    p "[sql.ru] parse_forum fid:#{fid} fname:#{fname}"
    fpg = 1

    link = "http://www.sql.ru/forum/#{fname}" + (fpg >1 ? "/#{fpg}" : "")

    page_noko = Nokogiri::HTML(downl(link))

    threads = page_noko.css("table.forumTable tr")

    thread_urls=[]
    page_threads =[]

    threads.drop(1).each_with_index do |tr,ind|

      url = tr.css("td.postslisttopic a")[0]['href']
      tid = url.scan(/\d+/)[0].to_i

      page_threads <<{
        fid: fid,
        tid: tid,
        title:tr.css("td.postslisttopic a")[0].text.encode('utf-8')[0..199],
        responses: tr.css("td")[3].text.to_i,
        updated: parse_date(tr.css("td")[5].text),
        #updated: tr.css("td")[5].text,
        descr:url.split('/').last[0..99],
        siteid:SID,
      }
      thread_urls << {tid:tid,url:url}
    end

    #page_threads.map { |tt| p tt[:updated] }
    Repo.insert_or_update_threads_for_forum(page_threads,SID)
    Repo.update_forum_bot_date(fid,SID)
    #p "[sql.ru] fid:#{fid} load threads num: #{page_threads.size}"


    #dowmload each thread
    page_threads.each_with_index{ |thr,ind| thr[:ind] = ind }

    Parallel.each(page_threads,:in_threads=>4) do |thr|
      tid = thr[:tid]
      ind = thr[:ind]

      next if ind<3 || ind>parse_thread_number

      resps=thr[:responses]
      page = Repo.calc_page(tid,resps+1,SID)

      #thread_pages = DB[:tpages].filter(siteid:SID, tid:tid).map([:page,:postcount])
      #url_tid = thread_urls.find{|arr| arr[:tid]==tid}
      #url = url_tid[:url] unless url_tid.nil?

      #title = SqlrHelper.get_thread_title(url)
      descr = "/"+thr[:descr]

      if page>0 #&& page<100
        posts =parse_thread(tid, page, descr)
        p "ind:#{ind} tid:#{tid} responses:#{resps} page:#{page} inserted:#{posts.size} title: #{thr[:descr]}"
      end

    end if need_parse_threads
  end

  def self.get_link(tid, page=1, title="")
    pp = page >1 ? "-#{page}" : "" 
    link = "http://www.sql.ru/forum/#{tid}#{pp}#{title}"
  end

  def self.parse_thread(tid, page=1,title=nil)

    link = get_link(tid,page,title)
    page_html = Nokogiri::HTML(downl(link)) rescue "error link: #{link}"
    
    parse_thread_from_html(tid, page, page_html)
  end

  def self.parse_thread_from_html(tid, page=1,page_html)
    posts = get_thread_page_posts(page_html,tid)
    #p posts.map{|el| el[:addedby]}

    inserted = Repo.insert_posts(posts, tid,SID)
    Repo.insert_or_update_tpage(SID,tid, page, posts.size)
    Repo.update_thread_bot_date(tid,SID)
    #p DB[:posts].where(siteid: 6, :tid => tid).select(:addeduid, :addedby).all
    p "tid:#{tid} page:#{page} inserted:#{posts.size}"
    posts
  end


  def self.get_thread_page_posts(page,tid)
    posts =[]
    page_posts =  page.css("table.msgTable")
    res=[]

    page_posts.each do |pst|
      begin
        post = {}
        if pst.css("tr td.msgBody:first a").empty?
          addedby = pst.css("tr td.msgBody:first").text.gsub(/\r\n/, "").strip
          uid = -1
        else
          addedby =  pst.css("tr td.msgBody:first a")[0].text.strip
          uid =  pst.css("tr td.msgBody:first a")[0]['href'].gsub(/\D/, "").to_i
        end

        post[:addedby] = addedby
        post[:addeduid] = uid
        post[:body] = pst.css("tr td.msgBody:last").inner_html.strip.encode('utf-8')

        mid = post[:mid] = pst.css("tr:last td.msgFooter a:first").text.to_i
        post[:tid] = tid

        date_str = pst.css("tr:last td.msgFooter > text()").text.gsub('[]', '').gsub('|', '').strip
        #p post[:mid] #if date_str.empty?

        post[:addeddate] = parse_date(date_str)
        post[:siteid] = SID

        res<<post if mid!=0

      rescue
        puts "error:get_page_posts tid:#{tid} #{$!.message}"
      end
    end

    res
  end

  def self.parse_date(date_str)
    return nil if date_str.empty?
    time = Time.strptime(date_str.split(',').last.strip,"%H:%M")
    date = SqlrHelper.parse_rudate(date_str.split(',').first, time)
  end

  def self.load_thread(tid, load_pages_back=1)
    crw_thread =  DB[:threads].filter(siteid:SID, tid:tid).first
    descr = crw_thread[:descr] if crw_thread
    descr= "/"+descr if descr && !descr.empty?
    p "[sql.ru] load_thread tid:#{tid} name:#{descr}"

    pages = DB[:tpages].filter(siteid:SID, tid:tid).to_hash(:page,:postcount)
    max_page = pages.max_by{|k,v| k}
    max_page = max_page.nil? ? 1: max_page.first
      
    #pages.sort.select { |pp|  pp[1]==20  }

    link = get_link(tid,max_page,descr)
    max_page_html = Nokogiri::HTML(downl(link))
    last = detect_last_page(max_page_html)
    #p "***********last:#{last} max:#{max_page} link" 

    counter=1
    last.downto(1).each do |pp|
      if pages[pp]!=25 #&& pp !=last
        break if counter> load_pages_back
        counter+=1

        posts = 
        if pp==max_page 
           p "---tid:#{tid} p:#{pp} loading...(last == max_db) "
          parse_thread_from_html(tid, pp, max_page_html) 
        else 
          p "---tid:#{tid} p:#{pp} loading... max:#{max_page} last:#{last}"
          parse_thread(tid, pp, descr) 
        end
        update_thread_attributes(tid, posts.last[:addeddate]) if pp==last
      end
    end
  end

  def self.update_thread_attributes(tid,last_post_date)
    #p "update last date #{last_post_date}"
    rec = DB[:threads].where(siteid:SID, tid:tid).update(updated: last_post_date)
  end 

  def self.detect_last_page(doc)
    nav = doc.css("div#content-wrapper-forum > table.sort_options tr td")
    page = nav.css("a").map { |ll| ll.text.to_i  }.max
    page||1
  end

  def self.test_detect_last_page_num(tid,page=1)
    p link = get_link(tid,page)
    max_page_html = Nokogiri::HTML(downl(link))
    p page = detect_last_page(max_page_html)
  end

end

#SqlrParser.parse_forum(16,false,50)
#p Repo.calc_page(1212142,182,6)
#SqlrParser.load_thread(1239274,5)
#SqlrParser.test_detect_last_page_num(1198365)
