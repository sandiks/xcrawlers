require 'nokogiri'
require 'open-uri'
require 'parallel'
require_relative  '../helpers/helper'
require_relative  '../repo'

#Powered by SMF 1.1.19

class SatsParser
  DB = Repo.get_db
  SID = 11
  THREAD_PAGE_SIZE =50
  @@need_save= true
  @@log =[]


  def self.check_forums(pages_back=1, need_parse_threads=false)
    forums = DB[:forums].filter(siteid:SID, check:1).map(:fid)

    Parallel.map(forums,:in_threads=>3) do |fid|
      #forums.each do |fid|
      parse_forum(fid, 1, need_parse_threads)
      #1.upto(pages_back) {|pg| parse_forum(fid, pg) }
    end

  end

  def self.parse_forum(fid, pg=1, need_parse_threads=false)

    pp = (pg>1 ? "_#{pg}_" : "")
    p link = "http://offtop.ru/satsang/1#{pp}.php"

    page = Nokogiri::HTML(download_page(link))
    #page = Nokogiri::HTML(File.open("btctalk128.html"))

    #threads = page.css('table[cellspacing="1"][cellpadding="3"]')
    threads = page.css('table.table1 tr')

    page_threads =[]

    threads.each_with_index do |tr,indx|
      next if tr.css("td").size != 6

      thr_a = tr.css("td.indx_top_td1 a")[0]
      thr_title = thr_a.text
      thr_link = thr_a['href']
      tid = thr_link.split('_')[1].to_i
      date = tr.css("td.indx_top_td5").text.strip
      date = DateTime.parse(date) rescue ""
      #p date = DateTime.strptime(date,"%D.%m.%y %H:%M").new_offset(3/24.0)

      page_threads << {
        fid:fid,
        tid:tid,
        title:thr_title,
        responses: tr.css("td.indx_top_td2").text.to_i,
        updated: date,
        siteid:SID,
      }
    end

    #page_threads.each_with_index { |tt, ind| p  "#{ind} #{tt[:title]} || #{tt[:updated]}"  }
    old_thread_resps = DB[:threads].filter(siteid:SID, fid: fid).to_hash(:tid,:responses)

    Repo.insert_or_update_threads_for_forum(page_threads,SID) if @@need_save
    DB[:forums].where(siteid:SID, fid:fid).update(bot_updated: DateTime.now.new_offset(3/24.0))

    if true#need_parse_threads
      load_forum_threads(fid, page_threads, old_thread_resps)
    end
  end

  def self.load_forum_threads(fid, page_threads, old_thread_resps)
  	#p "[load_forum_threads] fid:#{fid}"
    
    Parallel.map(page_threads,:in_threads=>2) do |thr|
    #page_threads.each do |thr|
      tid = thr[:tid]
      responses = thr[:responses]

      last_page_num = Repo.calc_last_page(responses+1, THREAD_PAGE_SIZE)
      lpage = last_page_num[0]
      lcount = last_page_num[1]

      old_resps = old_thread_resps[tid]
      downl_pages=calc_arr_downl_pages(tid,lpage,lcount).take(10)

      #p "[parse_thread_page] tid:#{tid} pg:#{downl_pages.to_s.ljust(20)} old:#{old_resps} new:#{responses}"
      downl_pages.each_with_index do |pp,idx|
        #break if idx>0   
        parse_thread_page(fid,tid, pp) rescue "[bctalk, load_forum_threads] error tid:#{tid}" 
      end 
      
    end
  end

  def self.calc_arr_downl_pages(tid,last_page,last_page_posts)
    need_parse_last_two =true
    downl_pages=[]

    if need_parse_last_two
        tpages = DB[:tpages].filter(siteid:SID, tid:tid).to_hash(:page,:postcount)
        downl_pages<<last_page if last_page_posts != tpages[last_page]

        (last_page-1).downto(1) do |pg|
          downl_pages<<pg if tpages[pg]!=THREAD_PAGE_SIZE 
        end
    end
    downl_pages
  end


  #----thread parser
  @@test = false

  def self.parse_thread_page(fid, tid, page=1)

    #link = get_link(tid,page)
    fname = "html/satsang-v#{fid}_#{tid}_#{page}_.html"
    
    link = "http://offtop.ru/satsang/v#{fid}_#{tid}_#{page}_.php"
    title = DB[:threads].where(siteid:SID, tid:tid).map(:title).first
    p "[thread] pg:#{page} title:#{title}"

    if true #need_downl
      page_html = Nokogiri::HTML(download_page(link))    
      #File.write(fname, page_html)
    else
      page_html = Nokogiri::HTML(File.open(fname)) if File.exist?(fname)
    end

    parse_thread_from_html(tid, page, page_html)
  end

  def self.parse_thread_from_html(tid, page, page_html)
    #p page_html.css("table.table1").size

    thread_posts = page_html.css("table.table1 > tr")

    posts =[]
    idx =0

    ##parse posts
    thread_posts.drop(1).each_slice(2).map do |trtr|
      next if trtr.size!=2
      tr1 = trtr[0]
      tr2 = trtr[1]

      if tr1
        link = tr1.css('td:nth-child(1) a')[0]
        if link
          url = link["href"]
          addedby = link.text.strip
          addeduid = url.split('=').last.to_i

        end

        post_date = tr1.css('td:nth-child(2) span').text.sub('Добавлено:','').strip
        post_date = DateTime.parse(post_date) rescue nil
      end

      body = tr2.css('td').inner_html.strip
      post_url = tr2.css('td div a')
      
      if post_url
        url = post_url[0]['href']
        mid = url.split('&')[0]
        mid = mid.split('=').last.to_i
      end

      posts<<{
        siteid:SID,
        mid:mid,
        tid:tid,
        body: body,
        addeduid:addeduid,
        addedby:addedby,
        addeddate: post_date,
        pnum:page
      }
    end

    #p "[info,parse_thread_from_html] tid:#{tid} p:#{page} size:#{posts.size}"
    #p posts.map { |pp| [ pp[:addeduid].to_s ] }

    users = posts.map { |pp| {siteid:SID, uid:pp[:addeduid], name:pp[:addedby]} }.uniq { |us| us[:uid] }

    if true
      Repo.insert_users(users,SID)
      Repo.insert_posts(posts, tid, SID)
      Repo.insert_or_update_tpage(tid,page,(posts.size==21 ? THREAD_PAGE_SIZE : posts.size),SID)
      Repo.update_thread_bot_date(tid,SID)
    else
      #title = DB[:threads].where(siteid:SID, tid:tid).map(:title)
      #p "tid:#{tid} page:#{page} inserted:#{posts.size} title:#{title}"
    end
    posts
  end

  def self.load_thread_par_from_start(fid, tid, pages_num=50)

    crw_thread =  DB[:threads].filter(siteid:SID, tid:tid).first
    title = crw_thread[:title] if crw_thread

    pages = DB[:tpages].filter(siteid:SID, tid:tid).to_hash(:page,:postcount)

    incomplete_pages =[]
    (1..1400).each { |pp|
      break if pages_num<1
      if pages[pp]!=THREAD_PAGE_SIZE
        incomplete_pages<<pp
        pages_num-=1
      end
    }
    p incomplete_pages
    Parallel.map_with_index(incomplete_pages,:in_threads=>4) do |pp, idx|
      #p "load_thread_par idx:#{idx} page:#{pp}"
      parse_thread_page(fid,tid, pp)
    end
  end


end
