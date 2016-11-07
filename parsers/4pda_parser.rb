require 'nokogiri'
require 'open-uri'
require 'parallel'
require_relative  '../helpers/helper'
require_relative  '../repo'

#Форум IP.Board © 2016  IPS, Inc.

class FpdaParser
  @@db = Repo.get_db
  @@sid = 10
  @@need_save= true
  @@log =[]

  def self.list_forums

    link ="http://4pda.ru/forum/index.php"

    #page = Nokogiri::HTML(download_page(link))
    page = Nokogiri::HTML(File.open("4PDA.html"))

    main_cats = page.css("div.borderwrap")
    #puts cats.map { |tr| tr.css(" td.row2 > b > a").text }
    #exit

    descr =""
    main_cats.each_with_index do |main_cat,indx|

      flink00 = main_cat.css("div.maintitle > p:nth-child(2)> a")[0]
      if flink00
        href = flink00['href']
        descr = flink00.text
        fid = href.split('=').last.to_i
      end
      next unless fid ==281 ||  fid ==607
      #next unless fid==203

      main_cat.css("tr").each_with_index do |cat,indx|


        if cat.css("td").size == 5
          flink = cat.css("td:nth-child(2) > b > a:first")[0]
          href = flink['href']
          ftitle = flink.text
          fid = fname = href.split('=').last.to_i

          @@need_save = (fid ==1)

          #insert level0 forum
          forum0 = {fid:fid, siteid:@@sid, title:ftitle, level:0, parent_fid:0, name:fname,  descr: descr }

          Repo.insert_or_update_forum(forum0,@@sid) if @@need_save

          subforums = []
          cat.css("td:nth-child(2) span.forumdesc > b >a").each do |ll|

            ftitle = ll.text
            flink = ll['href']
            fid = fname = flink.split('=').last.to_i

            subforums << {fid:fid, siteid:@@sid, title:ftitle, level:1,parent_fid:forum0[:fid], name:fname, descr: forum0[:title] } if fid!=0
          end

          Repo.insert_forums(subforums,@@sid) if @@need_save

          puts ""
          puts "[level 0] fid:#{forum0[:fid]} descr:#{forum0[:descr]} title:#{forum0[:title]}"
          subforums.each{|ff1| p "--- fid:#{ff1[:fid]} parent:#{ff1[:parent_fid]} title:#{ff1[:title]} descr:#{ff1[:descr]}"}
        end

      end
    end
  end

  def self.check_forums(need_parse_threads=false)
    forums = @@db[:forums].filter(siteid:@@sid, check:1).map(:fid)
    
    Parallel.map(forums,:in_threads=>3) do |fid|
    #forums.each do |fid|
      parse_forum(fid)
    end

  end

  def self.parse_forum(fid, pg=1, need_parse_threads=false)

    pp = (pg==1 ? "" : "&st=#{(pg-1)*30}") if pg>1

    p link = "http://4pda.ru/forum/index.php?showforum=#{fid}#{pp}"

    page = Nokogiri::HTML(download_page(link))
    #page = Nokogiri::HTML(File.open("f105.html"))

    threads = page.css("div.borderwrap table tr")

    page_threads =[]

    threads.each_with_index do |tr,indx|
      next if tr.css("td").size != 7

      thr_a = tr.css("td:nth-child(3) > div:nth-child(2) > span > a")[0]
      if thr_a
        thr_title = thr_a.text
        thr_href = thr_a['href']
        tid = thr_href.split('=').last.to_i
        descr =  tr.css("td:nth-child(3) > div:nth-child(2) > div.desc > span:first").text

        dates_str = tr.css("td:nth-child(7) span").children[0].text
        updated = parse_thread_last_date(dates_str)

        tt = {
          fid:fid,
          tid:tid,
          title:thr_title,
          responses: tr.css("td:nth-child(4) > a").text.to_i,
          updated: updated,
          descr: descr,
          siteid:@@sid,
        }
        #p "[#{indx}]-- #{tt}"
        page_threads<<tt
      end
    end
    Repo.insert_or_update_threads_for_forum(page_threads,@@sid) if @@need_save
  end

  def self.parse_thread_last_date(date_str)
    #Сегодня, 00:22
    if date_str.include? "Сегодня"
      date_str.gsub!("Сегодня",DateTime.now.strftime("%d.%m.%Y"))
    elsif date_str.include? "Вчера"
      date_str.gsub!("Вчера",(DateTime.now-1).strftime("%d.%m.%Y"))
    end
    date = DateTime.strptime(date_str,"%d.%m.%Y, %H:%M") rescue DateTime.new(1900,1,1) #.new_offset(3/24.0)
  end


  def self.check_selected_threads()

    threads = @@db[:threads].filter(siteid:@@sid, bot_tracked: 1).map(:tid)

    Parallel.map(threads,:in_threads=>4) do |tid|
      #threads.each do |tid|
      load_thread(tid)
    end

    puts @@log

  end

  def self.get_link(tid, page=1)
    link = "http://4pda.ru/forum/index.php?showtopic=#{tid}"
    link = "#{link}&st=#{(page-1)*20}" if page>1
    link
  end

  def self.load_thread(tid)
    crw_thread =  @@db[:threads].filter(siteid:@@sid, tid:tid).first
    title = crw_thread[:title] if crw_thread
    p "---tid:#{tid} loading"

    pages = @@db[:tpages].filter(siteid:@@sid, tid:tid).to_hash(:page,:postcount)
    #pages.sort.select { |pp|  pp[1]==20  }

    link = get_link(tid)
    page_html = Nokogiri::HTML(download_page(link))
    last = detect_last_page(page_html)/20+1

    cntr=1
    last.downto(1).each do |pp|
      if pages[pp]!=20 #&& pp !=last
        break if cntr>2
        cntr+=1
        posts = parse_thread(tid, pp)
        update_thread_attributes(tid,posts) if pp==last
      end
    end

  end

  def self.detect_last_page(doc)
    nav = doc.css("div#ipbwrapper > table.ipbtable[cellspacing='0'] tr td:first")
    href = nav.css("div > span.pagelinklast a")[0]['href']
    start = href.split('=').last.to_i
  end
  
  def self.update_thread_attributes(tid,posts)
    last_post_date = posts.last[:addeddate]
    #p "update last date #{last_post_date}"
    rec = @@db[:threads].where(siteid:@@sid, tid:tid).update(updated: last_post_date)
  end 

  def self.parse_thread(tid, page=1)

    link = get_link(tid,page)
    page_html = Nokogiri::HTML(download_page(link)) #if page_html.nil?
    #page_html = Nokogiri::HTML(File.open("tid717939.html"))

    thread_posts = page_html.css("div.borderwrap > table.ipbtable")

    posts =[]
    thread_posts.map do |post|
      mid = post.attr('data-post')

      if mid

        tr1 =post.css("tr:nth-child(1)")
        tr2 =post.css("tr:nth-child(2)")
        dates_str = tr1.css("td:nth-child(2) div span.postdetails")[0].text.strip
        post_date = parse_thread_last_date(dates_str)
        body = tr2.css('td:nth-child(2) div.postcolor')[0].inner_html.encode('utf-8').strip
        addedby_url = tr1.css("td:nth-child(1) div:first span.normalname a")[0]
        addedby = addedby_url.text.strip
        addeduid = addedby_url['href'].split('=').last.to_i

        posts<<{
          siteid:@@sid,
          mid:mid.to_i,
          tid:tid,
          body: body,
          addeduid:addeduid,
          addedby:addedby,
          addeddate: post_date,
          pnum:page
        }
      end

    end

    #p users = posts.map { |pp| [pp[:addeduid], pp[:addedby]]  }
    users = posts.map { |pp| {siteid:@@sid, uid:pp[:addeduid],name:pp[:addedby]}  }.uniq { |us| us[:uid] }

    Repo.insert_users(users,@@sid)
    Repo.insert_posts(posts, tid, @@sid)
    Repo.insert_or_update_tpage(tid,page,posts.size,@@sid)
    Repo.update_thread_bot_date(tid,@@sid)

    p "tid:#{tid} page:#{page} inserted:#{posts.size}"

    posts
  end
end

#FpdaParser.check_forums

#FpdaParser.parse_forum(105)
#FpdaParser.parse_thread(717939,28280/20+1)
    #FpdaParser.load_thread(718322)
    #FpdaParser.check_selected_threads
