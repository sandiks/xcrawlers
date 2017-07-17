require 'nokogiri'
require 'open-uri'
require 'parallel'
require_relative  '../helpers/helper'
require_relative  '../repo'

#Powered by SMF 1.1.19

class BCTalkParser
  DB = Repo.get_db
  SID = 9
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
      parse_forum(fid, 1)
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
      date = date[0..date.index('by')-1].strip
      if date.include? "Today"
        date.gsub!("Today at",DateTime.now.new_offset(0).strftime("%d.%m.%Y,"))
      end
      date = DateTime.parse(date) rescue ""
      #p date = DateTime.strptime(date,"%D.%m.%y %H:%M").new_offset(3/24.0)

      page_threads << {
        fid:fid,
        tid:tid,
        title:thr_title,
        responses: tr.css("td")[4].text.to_i,
        updated: date,
        siteid:SID,
      }

      p "[parse_forum: finished] #{thr_title} ||#{date}"
    end

    #page_threads.each_with_index { |tt, ind| p  "#{ind} #{tt[:title]} || #{tt[:updated]}"  }
    Repo.insert_or_update_threads_for_forum(page_threads,SID) if @@need_save
    DB[:forums].where(siteid:SID, fid:fid).update(bot_updated: DateTime.now.new_offset(3/24.0))
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
    pp = (page>1 ? "#{(page-1)*20}" : "0")
    link = "https://bitcointalk.org/index.php?topic=#{tid}.#{pp}"
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
    max_page_html = Nokogiri::HTML(download_page(link))
    last = (detect_last_page(max_page_html))
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
    #File.write("bctalk-tid#{tid}-p#{page}.html", page_html)
    
    #page_html = Nokogiri::HTML(File.open("html/bctalk-tid2006833-p2.html"))
    parse_thread_from_html(tid, page, page_html)

  end

  def self.parse_thread_from_html(tid, page, page_html)

    post_class = page_html.css("div#bodyarea > form > table.bordercolor tr").first.attr('class')
    thread_posts = page_html.css("div#bodyarea > form > table.bordercolor tr[class^='#{post_class}']")
    
    posts =[]
    idx =0

    thread_posts.map do |post|
      mid = post.css('a').first.attr('name')
      
      if mid

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
        end
        
        #p post_date_str = td2.css('table tr td:nth-child(2) div.smalltext')
        post_date_str = td2.css('td:nth-child(2) div.smalltext').text
        post_date = DateTime.parse(post_date_str)


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

    end

    #p "[info,parse_thread_from_html] tid:#{tid} p:#{page} size:#{posts.size}"
    #p posts.map { |pp| [ pp[:addeddate].to_s ] }
    
    users = posts.map { |pp| {siteid:SID, uid:pp[:addeduid],name:pp[:addedby]}  }.uniq { |us| us[:uid] }

    if true
        Repo.insert_users(users,SID)
        Repo.insert_posts(posts, tid, SID)
        Repo.insert_or_update_tpage(tid,page,(posts.size==21 ? 20 : posts.size),SID)
        Repo.update_thread_bot_date(tid,SID)
    end
    #p "tid:#{tid} page:#{page} inserted:#{posts.size}"

    posts
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

act=0
tid = 1628379

case act
when 1; BCTalkParser.list_forums
when 2; BCTalkParser.parse_forum(72,3)
when 3; BCTalkParser.check_forums
when 4; BCTalkParser.parse_thread_page(tid,1)
when 5; BCTalkParser.test_detect_last_page_num(tid,2)
else
  p "else "
end
