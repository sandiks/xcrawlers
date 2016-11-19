require 'nokogiri'
require 'open-uri'
require 'parallel'
require_relative  '../helpers/helper'
require_relative  '../repo'


class DXDYParser
  DB = Repo.get_db
  SID = 7
  @@need_save = true
  def self.list_forums

    p link ="http://dxdy.ru/"

    page = Nokogiri::HTML(download_page(link).body)
    #page = Nokogiri::HTML(File.open("s7.htm"))

    cats = page.css("div#wrapcentre table.tablebg > tbody[id='cat55'] > tr") #forums

    descr =""
    cats.each_with_index do |cat,indx|

      if cat.css("td").size == 2
        descr = cat.css("td:nth-child(1) a:first").text
      end

      if cat.css("td").size == 5
        flink = cat.css("td:nth-child(2) a:first")[0]['href']
        ftitle = cat.css("td:nth-child(2) > a:first").text
        fname = flink.split('/').last.sub(".html","")
        fid = fname.split('-').last.sub("f","").to_i

        #insert level0 forum
        forum0 = {fid:fid, siteid:SID, title:ftitle, level:0, parent_fid:0, name:fname,  descr: descr }

        Repo.insert_or_update_forum(forum0,SID) if @@need_save

        subforums = []
        cat.css("td:nth-child(2) p.forumdesc.forumicon a").each do |ll|

          ftitle = ll.text
          flink = ll['href']
          fname = flink.split('/').last.sub(".html","")
          fid = fname.split('-').last.sub("f","").to_i

          subforums << {fid:fid, siteid:SID, title:ftitle, level:1,parent_fid:forum0[:fid], name:fname } if fid!=0
        end

        Repo.insert_forums(subforums,SID) if @@need_save

        p "--------forum0 #{forum0[:descr]}"
        subforums[0..4].each{|ff1| p ff1 }
      end


    end
  end


  def self.check_forums(need_parse_threads=false)
    forums = DB[:forums].filter(siteid:SID, check:1).map(:fid)

    Parallel.each(forums,:in_threads=>3) do |fid|
    #forums.each do |fid|
      parse_forum(fid, need_parse_threads)
    end

  end

  def self.get_forum_name(fid)

    ff = DB[:forums].where(siteid:SID, fid:fid).first
    lev1 = ff[:name]

  end

  def self.parse_forum(fid, need_parse_threads=false)

    fname = get_forum_name(fid)

    p link = "http://dxdy.ru/#{fname}.html"

    page = Nokogiri::HTML(download_page(link))
    #page = Nokogiri::HTML(File.open("f10.html"))

    threads = page.css("div#pagecontent table.tablebg tr")

    page_threads =[]

    threads.each_with_index do |tr,indx|
      next if tr.css("td").size != 6

      thr_a = tr.css("td:nth-child(2) > a")[0]
      thr_title = thr_a.text
      thr_link = thr_a['href']
      tid = thr_link.split('/').last.scan(/\d+/)[0].to_i
      date_str = tr.css("td:nth-child(6) p:first").text
      date = DateTime.parse(date_str)
      #p date = DateTime.strptime(date_str,"%D.%m.%y %H:%M").new_offset(3/24.0)

      page_threads << {
        fid:fid,
        tid:tid,
        title:thr_title,
        responses: tr.css("td")[3].text.to_i,
        updated: date,
        siteid:SID,
      }
    end

    #page_threads.each_with_index { |tt, ind| p  "#{ind} #{tt[:title]} || #{tt[:updated]}"  }

    Repo.insert_or_update_threads_for_forum(page_threads,SID)

    Parallel.map(page_threads,:in_threads=>3) do |thr|

      tid = thr[:tid]
      page = Repo.calc_page(tid,thr[:responses],SID)

      thread_pages = DB[:tpages].filter(siteid:SID, tid:tid).map([:page,:postcount])
      resps = thr[:responses]

      inserted =parse_thread(fname,tid, page) if page>0
      p "tid:#{tid} resps:#{resps} page:#{page} inserted:#{inserted} thread:#{thread_pages}"

    end if need_parse_threads

  end


  def self.parse_thread(fname,tid, page=1)

  end

end


act=0

case act
when 1
  #DXDYParser.list_forums
  DXDYParser.check_forums
when 2
  DXDYParser.parse_forum(28)
end
