require 'nokogiri'
require 'open-uri'
require 'parallel'
require_relative  '../helpers/helper'
require_relative  '../repo'

#Powered by SMF 1.1.19

class BCTalkParser
  DB = Repo.get_db
  SID = 9
  THREAD_PAGE_SIZE =20
  @@need_save= true
  @@log =[]

  def self.list_forums

    link ="https://bitcointalk.org/index.php"

    page = Nokogiri::HTML(download_page(link))
    #page = Nokogiri::HTML(File.open("bctalk_main.html"))

    cats = page.css("div#bodyarea > div > table  > tr")
    #p cats.map { |tr| tr.css("td:nth-child(2) > b > a").text }
    #exit

    descr =""
    parent_fid = 0
    cats.each_with_index do |cat,indx|

      if cat.css("td").size == 1
        subforums = []
        cat.css("td span a").each do |ll|

          ftitle = ll.text
          href = ll['href']
          fid = href.split('=').last.to_i
          fname = "forum_#{fid}"

          subforums << {fid:fid, siteid:SID, title:ftitle, level:1,parent_fid: parent_fid, name:fname } if fid!=0

          Repo.insert_forums(subforums,SID) if @@need_save
        end
      end

      if cat.css("td").size == 4
        flink = cat.css("td:nth-child(2) > b > a")
        href = flink[0]['href']
        ftitle = flink[0].text
        fid = href.split('=').last.to_i
        fname = "forum_#{fid}" #flink.split('/').last.sub(".html","")
        parent_fid = fid

        #insert level0 forum
        p forum0 = {fid:fid, siteid:SID, title:ftitle, level:0, parent_fid: 0, name:fname,  descr: descr }

        Repo.insert_or_update_forum(forum0,SID) if @@need_save

        #p "--------forum0 #{forum0[:descr]}"
        #subforums[0..4].each{|ff1| p ff1 }
      end
    end
  end


  def self.check_forums(pages_back=1, need_parse_threads=false)
    forums = DB[:forums].filter(siteid:SID, check:1).map(:fid)

    Parallel.map(forums,:in_threads=>3) do |fid|
      #forums.each do |fid|
      parse_forum(fid, 1, need_parse_threads)
      #1.upto(pages_back) {|pg| parse_forum(fid, pg) }
    end

  end

  def self.parse_forum(fid, pg=1, need_parse_threads=false)

    pp = (pg>1 ? "#{(pg-1)*40}" : "0")
    p link = "https://bitcointalk.org/index.php?board=#{fid}.#{pp}"

    page = Nokogiri::HTML(download_page(link))
    #page = Nokogiri::HTML(File.open("btctalk128.html"))

    threads = page.css("div.tborder table tr")

    page_threads =[]

    threads.each_with_index do |tr,indx|
      next if tr.css("td").size != 7

      thr_a = tr.css("td:nth-child(3)  a")[0]
      thr_title = thr_a.text
      thr_link = thr_a['href']
      tid = thr_link.split('=').last.scan(/\d+/)[0].to_i
      date = tr.css("td:nth-child(7) span").text.strip
      date_str = date[0..date.index('by')-1].strip
      date = parse_post_date(date_str)

      page_threads << {
        fid:fid,
        tid:tid,
        title:thr_title,
        responses: tr.css("td")[4].text.to_i,
        viewers: tr.css("td")[5].text.to_i,
        updated: date,
        siteid:SID,
      }
    end

    #page_threads.each_with_index { |tt, ind| p  "#{ind} #{tt[:title]} || #{tt[:updated]}"  }
    old_thread_resps = DB[:threads].filter(siteid:SID, fid: fid).to_hash(:tid,:responses)

    Repo.insert_or_update_threads_for_forum(page_threads,SID) if @@need_save
    DB[:forums].where(siteid:SID, fid:fid).update(bot_updated: DateTime.now.new_offset(3/24.0))

    if need_parse_threads
      load_forum_threads(fid, page_threads, old_thread_resps)
    end
  end

  def self.load_forum_threads(fid, page_threads, old_thread_resps)
  	p "[load_forum_threads] fid:#{fid}"
    
    Parallel.map_with_index(page_threads,:in_threads=>3) do |thr,idx|
    #page_threads.each do |thr|
      tid = thr[:tid]
      responses = thr[:responses]
      last_page_num = Repo.calc_last_page(responses+1,20)
      lpage = last_page_num[0]
      lcount = last_page_num[1]

      old_resps = old_thread_resps[tid]
      downl_pages=calc_arr_downl_pages(tid,lpage,lcount).take(2)

      p "[#{idx} parse_thread_page] tid:#{tid} pg:#{downl_pages.to_s.ljust(20)} old:#{old_resps} new:#{responses}"
      downl_pages.each do |pp|   
        parse_thread_page(tid, pp) rescue "[bctalk, load_forum_threads] error tid:#{tid}" 
      end
      
    end
  end

  def self.calc_arr_downl_pages(tid,last_page,last_page_posts)
    downl_pages=[]

    tpages = DB[:tpages].filter(siteid:SID, tid:tid).to_hash(:page,:postcount)
    downl_pages<<last_page if last_page_posts != tpages[last_page]

    (last_page-1).downto(1) do |pg|
      downl_pages<<pg if tpages[pg]!=THREAD_PAGE_SIZE 
    end

    downl_pages
  end
  
  #----thread parser
  def self.check_selected_threads()

    threads = DB[:threads].filter(siteid:SID, bot_tracked: 1).map(:tid)
    Parallel.map(threads,:in_threads=>4) do |tid|
      #threads.each do |tid|
      load_thread(tid) rescue "[bctalk, check_selected_threads] error tid:#{tid}"
    end
    puts @@log
  end

  def self.get_link(tid, page=1)
    pp = (page>1 ? "#{(page-1)*THREAD_PAGE_SIZE}" : "0")
    link = "https://bitcointalk.org/index.php?topic=#{tid}.#{pp}"
  end

  def self.load_thread(tid, load_pages_back=1)
    p "downl thread tid:#{tid} pages_back:#{load_pages_back} use tor:false"

    crw_thread =  DB[:threads].filter(siteid:SID, tid:tid).first
    title = crw_thread[:title] if crw_thread

    pages = DB[:tpages].filter(siteid:SID, tid:tid).to_hash(:page,:postcount)
    max_page = pages.max_by{|k,v| k}
    last_db_page = max_page.nil? ? 1: max_page.first

    link = get_link(tid,last_db_page)
    max_page_html = Nokogiri::HTML(download_page(link))
    last = (detect_last_page(max_page_html))||1
    #p "***********last_db_page:#{last_db_page} last_site:#{last}"  #if last>3000

    counter=1
    last.downto(1).each do |pp|

      if pages[pp]!=THREAD_PAGE_SIZE #&& pp !=last
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
  def self.load_thread_par_from_start(tid, pages_num=50)

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
      p "load_thread_par idx:#{idx} page:#{pp}"
      parse_thread_page(tid, pp)
    end
  end

  def self.update_thread_attributes(tid,last_post_date)
    #p "update last date #{last_post_date}"
    rec = DB[:threads].where(siteid:SID, tid:tid).update(updated: last_post_date)
  end

  @@test = false

  def self.parse_thread_page(tid, page=1)

    link = get_link(tid,page)
    fname = "html/bctalk-tid#{tid}-p#{page}.html"
    page_html = Nokogiri::HTML(download_page(link))
    
    #File.write(fname, page_html)
    #page_html = Nokogiri::HTML(File.open(fname)) if File.exist?(fname)

    parse_thread_from_html(tid, page, page_html)
  end

  def self.parse_thread_from_html(tid, page, page_html)

    post_class = page_html.css("div#bodyarea > form > table.bordercolor tr").first.attr('class')
    top_mid = page_html.css("div#bodyarea > a")[1]
    top_mid = top_mid['name']

    thread_posts = page_html.css("div#bodyarea > form > table.bordercolor tr[class^='#{post_class}']")

    posts =[]
    rank={}
    idx =0

    ##parse posts
    thread_posts.map do |post|

      mid = post.css('a').first.attr('name')
      ##set top mid
      mid =top_mid unless mid

      post_tr = post.css('table tr > td > table > tr').first #td[class~="windowbg windowbg2"]

      td1=post_tr.css('td')[0]
      td2=post_tr.css('td')[1]

      if idx==10 && false
        File.write("html/post_tr.html", post_tr.to_s)
        File.write("html/td1.html", td1.to_s)
        File.write("html/td2.html", td2.to_s)
      end
      idx+=1

      if td1
        link = td1.css('a')[0]
        url = link["href"]
        addedby = link.text.strip
        addeduid = url.split('=').last.to_i

        rank[addeduid] = detect_user_rank(td1)
      end

      #p post_date_str = td2.css('table tr td:nth-child(2) div.smalltext')
      post_date_str = td2.css('td:nth-child(2) div.smalltext').text
      post_date = parse_post_date(post_date_str)


      #body = td2.css('div.post').inner_html.force_encoding('ISO-8859-1').encode('UTF-8').strip
      body = td2.css('div.post').inner_html.strip
      mid = mid.sub('msg','').to_i


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
    #p posts.map { |pp| [ pp[:addeddate].to_s ] }

    users = posts.map { |pp| {siteid:SID, uid:pp[:addeduid], name:pp[:addedby], rank:rank[pp[:addeduid]]} }.uniq { |us| us[:uid] }

    if true
      Repo.insert_users(users,SID)
      Repo.insert_posts(posts, tid, SID)
      Repo.insert_or_update_tpage(tid,page,(posts.size==21 ? THREAD_PAGE_SIZE : posts.size),SID)
      Repo.update_thread_bot_date(tid,SID)
    else
      title = DB[:threads].where(siteid:SID, tid:tid).map(:title)
      p "tid:#{tid} page:#{page} inserted:#{posts.size} title:#{title}"
    end
    posts
  end

  ##11-legendary
  def self.detect_user_rank(td)
    stars = td.css('div.smalltext > img[alt="*"]')
    legend = stars.first['src'].end_with?("legendary.gif") rescue false
    staff = stars.first['src'].end_with?("staff.gif") rescue false
    rank = legend || staff ? 11 : stars.size
  end

  def self.parse_post_date(date_str)
   
    now = DateTime.now.new_offset(3.0/24)

    date = DateTime.parse(date_str) rescue DateTime.new(1900,1,1) #.new_offset(3/24.0)
    date>now ? date-1 : date
  end

  def self.detect_last_page(doc)
    nav = doc.css("div#bodyarea > table tr td:first a")
    max = nav.map { |ll| ll.text.to_i  }.max
  end

  def self.test_detect_last_page_num(tid,page=1)
    p link = get_link(tid,page)
    page_html = Nokogiri::HTML(download_page(link))
    #page_html = Nokogiri::HTML(File.open("html/bctalk-tid2006833-p2.html"))

    p last = detect_last_page(page_html)
  end
end
