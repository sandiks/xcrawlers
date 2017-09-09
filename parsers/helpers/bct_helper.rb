require 'nokogiri'
require 'open-uri'
require 'parallel'
require_relative  '../../helpers/helper'
require_relative  '../../helpers/repo'

class BCTalkParserHelper
  @@need_save= true
  SID=9
  DB = Repo.get_db


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

          puts subforums << {fid:fid, siteid:SID, title:ftitle, level:1,parent_fid: parent_fid, name:fname } if fid!=0

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

    #----thread parser
  def self.check_selected_threads()

    threads = DB[:threads].filter(siteid:SID, bot_tracked: 1).map(:tid)
    Parallel.map(threads,:in_threads=>4) do |tid|
      #threads.each do |tid|
      load_thread(tid) rescue "[bctalk, check_selected_threads] error tid:#{tid}"
    end
    puts @@log
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
          posts = BCTalkParser.parse_thread_from_html(tid, pp, max_page_html)
        else
          p "---tid:#{tid} p:#{pp} loading... "
          posts = BCTalkParser.parse_thread_page(tid, pp)
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

  def self.detect_last_page(doc)
    nav = doc.css("div#bodyarea > table tr td:first a")
    max = nav.map { |ll| ll.text.to_i  }.max
  end  
end

#BCTalkParserHelper.list_forums