require 'nokogiri'
require 'open-uri'
require 'parallel'
require_relative  '../helpers/helper'
require_relative  '../repo'

#Форум IP.Board © 2016  IPS, Inc.

class FpdaParser
  DB = Repo.get_db
  SID = 10
  @@need_save= true
  @@log =[]

  def self.list_forums

    link ="http://4pda.ru/forum/index.php"

    #page = Nokogiri::HTML(download_page(link))
    #page = Nokogiri::HTML(File.open("4PDA.html"))

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
          forum0 = {fid:fid, siteid:SID, title:ftitle, level:0, parent_fid:0, name:fname,  descr: descr }

          Repo.insert_or_update_forum(forum0,SID) if @@need_save

          subforums = []
          cat.css("td:nth-child(2) span.forumdesc > b >a").each do |ll|

            ftitle = ll.text
            flink = ll['href']
            fid = fname = flink.split('=').last.to_i

            subforums << {fid:fid, siteid:SID, title:ftitle, level:1,parent_fid:forum0[:fid], name:fname, descr: forum0[:title] } if fid!=0
          end

          Repo.insert_forums(subforums,SID) if @@need_save

          puts ""
          puts "[level 0] fid:#{forum0[:fid]} descr:#{forum0[:descr]} title:#{forum0[:title]}"
          subforums.each{|ff1| p "--- fid:#{ff1[:fid]} parent:#{ff1[:parent_fid]} title:#{ff1[:title]} descr:#{ff1[:descr]}"}
        end

      end
    end
  end

  def self.downl(link)
    download_page(link)
  end

  def self.check_forums(pages_back=1, need_parse_threads=false)
    forums = DB[:forums].filter(siteid:SID, check:1).map(:fid)

    Parallel.map(forums,:in_threads=>3) do |fid|
      #forums.each do |fid|
      1.upto(pages_back) {|pg| parse_forum(fid, pg) }
    end
  end

  def self.parse_forum(fid, pg=1, need_parse_threads=false)

    p "download 4pda forum fid=#{fid} page:#{pg}"

    pp = (pg>1 ? "&st=#{(pg-1)*30}" : "") 

    link = "https://4pda.ru/forum/index.php?showforum=#{fid}#{pp}"

    page_html = Nokogiri::HTML(downl(link))
    #File.write("4pda-fid#{fid}-p#{pg}.html", page_html)
    #page_html = Nokogiri::HTML(File.open("f105.html"))

    threads = page_html.css("div.borderwrap table tr")

    page_threads =[]

    threads.each_with_index do |tr,indx|
      next if tr.css("td").size < 7

      thr_a = tr.css("td:nth-child(3) > div:nth-child(2) > span > a")[0]
      if thr_a
        thr_title = thr_a.text
        thr_href = thr_a['href']
        tid = thr_href.split('=').last.to_i
        descr =  tr.css("td:nth-child(3) > div:nth-child(2) > div.desc > span:first").text

        dates_str = tr.css("td:nth-child(7) span > text()")
        updated = parse_thread_last_date(dates_str)

        tt = {
          fid:fid,
          tid:tid,
          title:thr_title,
          responses: tr.css("td:nth-child(4) > a").text.to_i,
          updated: updated,
          descr: descr,
          siteid:SID,
        }
        #p "[#{indx}]-- #{tt}"
        page_threads<<tt
      end
    end

    #p page_threads.map{|tt| tt[:title]}
    Repo.insert_or_update_threads_for_forum(page_threads,SID,true) if @@need_save
    DB[:forums].where(siteid:SID, fid:fid).update(bot_updated: DateTime.now.new_offset(3/24.0))
  end

  def self.parse_thread_last_date(date_node)
    if not date_node
      p "error [4pda, parse_thread_last_date]"
      return nil
    end
    date_str = date_node.text.strip
    now = DateTime.now.new_offset(3.0/24)

    #Сегодня, 00:22
    if date_str.include? "Сегодня"
      date_str.gsub!("Сегодня",now.strftime("%d.%m.%y"))
    elsif date_str.include? "Вчера"
      date_str.gsub!("Вчера",(now-1).strftime("%d.%m.%y"))
    end
    date = DateTime.strptime(date_str,"%d.%m.%y, %H:%M") rescue DateTime.new(1900,1,1) #.new_offset(3/24.0)
    date>now ? date-1 : date

  end


  def self.check_selected_threads()

    threads = DB[:threads].filter(siteid:SID, bot_tracked: 1).map(:tid)

    Parallel.map(threads,:in_threads=>4) do |tid|
      #threads.each do |tid|
      load_thread(tid) rescue "[4pda, check_selected_threads] error tid:#{tid}"
    end

    puts @@log

  end

  def self.get_link(tid, page=1)
    link = "http://4pda.ru/forum/index.php?showtopic=#{tid}"
    link = "#{link}&st=#{(page-1)*20}" if page>1
    link
  end

  def self.load_thread(tid, load_pages_back=1)
    #p "downl thread tid:#{tid} pages_back:#{load_pages_back} use tor:false"

    crw_thread =  DB[:threads].filter(siteid:SID, tid:tid).first
    title = crw_thread[:title] if crw_thread

    pages = DB[:tpages].filter(siteid:SID, tid:tid).to_hash(:page,:postcount)
    max_page = pages.max_by{|k,v| k}
    last_db_page = max_page.nil? ? 1: max_page.first

    #pages.sort.select { |pp|  pp[1]==20  }

    link = get_link(tid,last_db_page)
    max_page_html = Nokogiri::HTML(downl(link))
    last = (detect_last_page(max_page_html)/20+1)
    p "***********last_db_page:#{last_db_page} last_site:#{last}"  #if last>3000

    counter=1
    last.downto(1).each do |pp|

      if pages[pp]!=20 #&& pp !=last
        break if counter> load_pages_back
        counter+=1

        if pp==last_db_page 
           p "---tid:#{tid} p:#{pp} loading...(last_db == last) "
          posts = parse_thread_from_html(tid, pp, max_page_html) 
        else 
          p "---tid:#{tid} p:#{pp} loading... "
          posts = parse_thread_page(tid, pp) 
        end

        update_thread_attributes(tid, posts.last[:addeddate]) if pp==last
      end
    end

  end
  
  def self.update_thread_attributes(tid,last_post_date)
    #p "update last date #{last_post_date}"
    rec = DB[:threads].where(siteid:SID, tid:tid).update(updated: last_post_date)
  end 
  
  def self.parse_thread_page(tid, page=1)
    link = get_link(tid,page)
    page_html = Nokogiri::HTML(download_page(link)) #if page_html.nil?
    #File.write("4pda-tid#{tid}-p#{page}.html", page_html)
    parse_thread_from_html(tid, page, page_html)

  end

  def self.parse_thread_from_html(tid, page, page_html)

    #page_html = Nokogiri::HTML(File.open("tid717939.html"))
    thread_posts = page_html.css("div.borderwrap > table.ipbtable")

    posts =[]
    thread_posts.map do |post|
      mid = post.attr('data-post')

      if mid

        tr1 =post.css("tr:nth-child(1)")
        tr2 =post.css("tr:nth-child(2)")
        dates_str = tr1.css("td:nth-child(2) > text()")
        post_date = parse_thread_last_date(dates_str)

        body = tr2.css('td:nth-child(2) div.postcolor')[0].inner_html.encode('utf-8').strip
        addedby_url = tr1.css("td:nth-child(1) div:first span.normalname a")[0]
        addedby = addedby_url.text.strip
        addeduid = addedby_url['href'].split('=').last.to_i

        posts<<{
          siteid:SID,
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

    #p "[info,parse_thread_from_html] tid:#{tid} p:#{page} size:#{posts.size}"
    #p posts.map { |pp| [ pp[:addeddate].to_s ] }
    
    users = posts.map { |pp| {siteid:SID, uid:pp[:addeduid],name:pp[:addedby]}  }.uniq { |us| us[:uid] }

    Repo.insert_users(users,SID)
    Repo.insert_posts(posts, tid, SID)
    Repo.insert_or_update_tpage(tid,page,(posts.size==21 ? 20 : posts.size),SID)
    Repo.update_thread_bot_date(tid,SID)

    #p "tid:#{tid} page:#{page} inserted:#{posts.size}"

    posts
  end
  
  def self.detect_last_page(doc)
    nav = doc.css("div#ipbwrapper > table.ipbtable[cellspacing='0'] tr td:first")
    #href = nav.css("div > span.pagelinklast a")[0]['href']
    href = nav.css("div > span.pagelinklast  a").select { |ll| ll[:href].include? "&st="  }
    start = (href.size>0 ? href[0][:href].split('=').last.to_i : 0)
  end

  def self.test_detect_last_page_num(tid,page=1)
    p link = get_link(tid,page)
    max_page_html = Nokogiri::HTML(download_page(link))
    start_from = detect_last_page(max_page_html)
    last = (start_from/20+1)
  end
end

#FpdaParser.check_forums
#FpdaParser.parse_forum(1,1)
#FpdaParser.parse_thread_page(775882,156)
#FpdaParser.load_thread(745310,3)
#FpdaParser.check_selected_threads
#p FpdaParser.test_detect_last_page_num(745310,1)
