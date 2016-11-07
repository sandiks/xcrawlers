require 'nokogiri'
require 'open-uri'
require 'parallel'
require_relative  '../helpers/helper'
require_relative  '../repo'

#Powered by SMF 1.1.19

class BCTalkParser
  @@db = Repo.get_db
  @@sid = 9
  @@need_save= true


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

          subforums << {fid:fid, siteid:@@sid, title:ftitle, level:1,parent_fid: parent_fid, name:fname } if fid!=0

          Repo.insert_forums(subforums,@@sid) if @@need_save
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
        p forum0 = {fid:fid, siteid:@@sid, title:ftitle, level:0, parent_fid: 0, name:fname,  descr: descr }

        Repo.insert_or_update_forum(forum0,@@sid) if @@need_save

        #p "--------forum0 #{forum0[:descr]}"
        #subforums[0..4].each{|ff1| p ff1 }
      end
    end
  end

  def self.check_forums(need_parse_threads=false)
    forums = @@db[:forums].filter(siteid:@@sid, check:1).map(:fid)
    forums.each do |fid|
      parse_forum(fid, need_parse_threads)
    end

  end

  def self.parse_forum(fid, need_parse_threads=false)

    p link = "https://bitcointalk.org/index.php?board=#{fid}.0"

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
        siteid:@@sid,
      }
    end

    #page_threads.each_with_index { |tt, ind| p  "#{ind} #{tt[:title]} || #{tt[:updated]}"  }
    Repo.insert_or_update_threads_for_forum(page_threads,@@sid) if @@need_save
  end

end

act=-1

BCTalkParser.list_forums if act==0
BCTalkParser.parse_forum(1) if act==1
BCTalkParser.check_forums if act==2
