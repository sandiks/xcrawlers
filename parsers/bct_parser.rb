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
  @@from_date = DateTime.now.new_offset(0/24.0)-0.5


  def self.check_forums(pages_back=1, need_parse_threads=false)
    forums = DB[:forums].filter(siteid:SID, check:1).map(:fid)

    Parallel.map(forums,:in_threads=>3) do |fid|
      #forums.each do |fid|
      parse_forum(fid, 1, need_parse_threads)
      #1.upto(pages_back) {|pg| parse_forum(fid, pg) }
    end

  end

  def self.downl_forum_pages_for_last_day(fid, start_page=1) 

    start_page.upto(start_page+10) do |pg|
      next if pg<1
      dd = parse_forum(fid,pg,true)
      break if dd<@@from_date rescue "[error] fdate <start_date"
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
    
    Parallel.map_with_index(page_threads,:in_threads=>3) do |thr,idx|
    #page_threads.each do |thr|
      tid = thr[:tid]

      #next if tid!=2047476

      responses = thr[:responses]
      page_and_num = Repo.calc_last_page(responses+1,20)
      lpage = page_and_num[0]
      lcount = page_and_num[1]

      old_resps = old_thread_resps[tid]

      downl_pages=calc_arr_downl_pages(tid,lpage,lcount,@@from_date).take(3)

      res=[]
      downl_pages.each do |pp|   
        res<<pp[0]
        data = parse_thread_page(tid, pp[0]) rescue "[bctalk, load_forum_threads] error tid:#{tid}"
        break if data[:first_post_date]<@@from_date rescue "[error] fdate <start_date"
      end      
      planned_str=downl_pages.map { |pp| "#{pp[0]}*#{pp[1]}"   }.join(', ')

      p "[#{idx} load_thr:#{tid} resp:#{responses} last:#{page_and_num}]".ljust(50)+"planned:#{planned_str.ljust(20)} downl:#{res.to_s.ljust(20)} updated:#{thr[:updated].strftime("%F %H:%M:%S") }"
    end

    page_threads.last[:updated] #return last thread updated date

  end

  def self.calc_arr_downl_pages(tid,last_page,last_page_posts,fp_date)
    downl_pages=[]

    #tpages = DB[:tpages].filter(Sequel.lit("siteid=? and tid=? and fp_date > ?", SID, tid, fp_date)).to_hash(:page,:postcount)
    tpages = DB[:tpages].filter(Sequel.lit("siteid=? and tid=?", SID, tid)).to_hash(:page,:postcount)
    downl_pages<<[last_page,tpages[last_page]] if last_page_posts-(tpages[last_page]||0)>2

    (last_page-1).downto(last_page-2) do |pg|
      break if pg<1
      #downl_pages<<pg if tpages[pg]!=THREAD_PAGE_SIZE 
      downl_pages<<[pg, tpages[pg]] if tpages[pg]!=THREAD_PAGE_SIZE 
    end

    downl_pages
  end
  
  def self.get_link(tid, page=1)
    pp = (page>1 ? "#{(page-1)*THREAD_PAGE_SIZE}" : "0")
    link = "https://bitcointalk.org/index.php?topic=#{tid}.#{pp}"
  end

  def self.parse_thread_page(tid, page=1)
    return if page<1

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
        body: "", #body,
        addeduid:addeduid,
        addedby:addedby,
        addeddate: post_date,
        pnum:page
      }
    end

    #p "[info,parse_thread_from_html] tid:#{tid} p:#{page} size:#{posts.size}"
    #p posts.map { |pp| [ pp[:addeddate].to_s ] }

    users = posts.map { |pp| {siteid:SID, uid:pp[:addeduid], name:pp[:addedby], rank:rank[pp[:addeduid]]} }.uniq { |us| us[:uid] }
    first_post_date = posts.first[:addeddate]

    if true #need save
      Repo.insert_users(users,SID)
      Repo.insert_posts(posts, tid, SID)
      Repo.insert_or_update_tpage(SID,tid,page,posts.size,first_post_date)
      Repo.update_thread_bot_date(tid,SID)
    else
      title = DB[:threads].where(siteid:SID, tid:tid).map(:title)
      p "tid:#{tid} page:#{page} inserted:#{posts.size} title:#{title}"
    end

    
    #p "[ parse_thread_page_html] tid:#{tid} pg:#{page} first:#{first_date.strftime("%F %H:%M")}"

    {first_post_date: first_post_date} 
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

end
