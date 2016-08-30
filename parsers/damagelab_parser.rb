require 'nokogiri'
require 'open-uri'
require 'parallel'
require_relative  '../helpers/helper'
require_relative  '../repo'


class DamageLabParser
  @@db = Repo.get_db
  @@sid = 8
  @@need_save= true
  def self.list_forums


    #p link ="https://damagelab.org/index.php?showforum=1"
    p link ="https://damagelab.org/index.php?act=idx"

    page = Nokogiri::HTML(download_page(link))
    #page = Nokogiri::HTML(File.open("dam.htm"))

    cats = page.css("div#ipbwrapper div[id=\"fo_1\"] table tr")
    #p cats.map { |tr| tr.css("td:nth-child(2)  a:first").text }

    descr ="Андерграунд"
    cats.each_with_index do |cat,indx|

      if cat.css("td").size == 2
        descr = cat.css("td:nth-child(1) a:first").text
      end

      if cat.css("td").size == 5
        flink = cat.css("td:nth-child(2) a:first")
        href = flink[0]['href']
        ftitle = flink[0].text
        fid = href.split('=').last.to_i
        fname = "forum_#{fid}" #flink.split('/').last.sub(".html","")

        #insert level0 forum
        p forum0 = {fid:fid, siteid:@@sid, title:ftitle, level:1, parent_fid:1000, name:fname,  descr: descr }

        Repo.insert_or_update_forum(forum0,@@sid) if @@need_save

        subforums = []
        cat.css("td:nth-child(2) p.forumdesc.forumicon a").each do |ll|

          ftitle = ll.text
          flink = ll['href']
          fname = flink.split('/').last.sub(".html","")
          fid = fname.split('-').last.sub("f","").to_i

          subforums << {fid:fid, siteid:@@sid, title:ftitle, level:1,parent_fid:forum0[:fid], name:fname } if fid!=0
        end

        Repo.insert_forums(subforums,@@sid) if @@need_save

        #p "--------forum0 #{forum0[:descr]}"
        #subforums[0..4].each{|ff1| p ff1 }
      end


    end
  end


  def self.check_forums(need_parse_threads=false)
    forums = @@db[:forums].filter(siteid:@@sid, level:1).map(:fid)
    forums.each do |fid|
      parse_forum(fid, need_parse_threads)
    end

  end

  def self.get_forum_name(fid)

    ff = @@db[:forums].where(siteid:@@sid, fid:fid).first
    lev1 = ff[:name]

  end

  def self.parse_forum(fid, need_parse_threads=false)

    p link = "https://damagelab.org/index.php?showforum=#{fid}"

    page = Nokogiri::HTML(download_page(link))
    #page = Nokogiri::HTML(File.open("for2.htm"))

    max= page.css("div.borderwrap").map.with_index { |dd,i|  [i,dd.css("table tr").size]  }.max_by(&:last).first
    return if max.nil?
    threads = page.css("div.borderwrap")[max].css("table tr")

    page_threads =[]

    threads.each_with_index do |tr,indx|
      next if tr.css("td").size != 7

      thr_a = tr.css("td")[2].css("div a").select { |e| e['onmousemove'] }.first
      next if thr_a.nil?

      thr_title = thr_a.text
      thr_link = thr_a['href']
      tid = thr_link.split("&showtopic=").last.scan(/\d+/)[0].to_i
      dates = tr.css("td:nth-child(7) span div").children[0].text
      if dates.include? "Сегодня"
        dates.gsub!("Сегодня",DateTime.now.strftime("%d.%m.%y"))
      end
      #date = DateTime.parse(dates)
      date = DateTime.strptime(dates,"%d.%m.%y, %H:%M") rescue DateTime.new(1900,1,1) #.new_offset(3/24.0)

      page_threads << {
        fid:fid,
        tid:tid,
        title:thr_title,
        responses: tr.css("td")[3].text.to_i,
        updated: date,
        siteid:@@sid,
      }
    end

    #page_threads.each_with_index { |tt, ind| p  "#{ind} #{tt[:tid]}|| #{tt[:title]} || #{tt[:updated]}"  }
    Repo.insert_or_update_threads_for_forum(page_threads,@@sid)

    Parallel.map(page_threads,:in_threads=>3) do |thr|

      tid = thr[:tid]
      page = Repo.calc_page(tid,thr[:responses],@@sid)

      thread_pages = @@db[:tpages].filter(siteid:@@sid, tid:tid).map([:page,:postcount])
      resps = thr[:responses]

      inserted =parse_thread(fname,tid, page) if page>0
      p "tid:#{tid} resps:#{resps} page:#{page} inserted:#{inserted} thread:#{thread_pages}"

    end if need_parse_threads

  end


  def self.parse_thread(fname,tid, page=1)
  end

end


act=0

DamageLabParser.parse_forum(65) if act==1
DamageLabParser.check_forums if act==2
