require 'nokogiri'
require 'open-uri'
require 'parallel'
require_relative  '../helpers/helper'
require_relative  '../helpers/rsn_helper'
require_relative  '../repo'
require_relative  '../cmd_helper'

class RsnParser
  SID=2
  DB = Repo.get_db

  def self.check_forums(need_parse_threads=false)

    forums = DB[:forums].filter(siteid:SID,check: 1).all

    Parallel.map(forums,:in_threads=>3) do |ff|
    #forums.each do |ff|
      parse_forum(ff[:fid], need_parse_threads) if need_parse_forum(ff[:fid],SID) #rescue puts "error[RsnParser] check forum #{ff[:fid]}"

    end
  end

  def self.parse_forum(fid, need_parse_threads=false)

    p "[rsdn.org] parse_forum fid:#{fid}"

    page_threads=[]

    start = 1 #1,21,41,...
    url  ="http://rsdn.org/Forum/MsgList.aspx?gid=#{fid}&start=#{start}&flat=0&rate=0&IsFAQ=0"
    page_threads += get_forum_threads(fid, url)
		
		#page_threads.map { |tt| p tt[:title] }
    
    Repo.insert_or_update_threads_for_forum(page_threads,2)
    Repo.update_forum_bot_date(fid,2)

    Parallel.map(page_threads,:in_threads=>3) do |thr|
      #page_threads.each do |thr|
      tid = thr[:tid]

      #next if not tid==10856785

      resps=thr[:responses]+1
      page = Repo.calc_page(tid,resps,SID)

      thread_pages = DB[:tpages].filter(siteid:2, tid:tid).map([:page,:postcount])

      inserted = parse_thread(thr[:descr], page) if page>0

      p "tid:#{tid} resps:#{resps} page:#{page} inserted:#{inserted} thread:#{thread_pages}"

    end if need_parse_threads

  end

  def self.get_forum_threads(fid, url)

    page = Nokogiri::HTML(download_page(url))
    #page = Nokogiri::HTML(File.open("1.htm"))

    topics = []
    recs =  page.css("#tbl > tr")
    recs[1..-2].each do  |thr|

      title = thr.css("td")[0].text.strip
      url = thr.css('td')[0].css('table a')[0]['href']
      smid = smid_from_url(url)
      #fname = forum_name_from_url(url)

      responses= thr.css('>td')[3].text.to_i
      date_str= thr.css('>td')[4].text
      begin
        updated_at = DateTime.strptime(date_str,"%d.%m %H:%M")
      rescue
        updated_at = DateTime.strptime(date_str,"%d.%m.%y")
      end

      #when month is 12 we should fix year -1
      updated_at = updated_at >> -12 if updated_at > DateTime.now
      #p "#{smid} #{updated_at}"

      topics << {
        siteid:SID,
        fid:fid,
        tid:smid,
        title:title,
        updated:updated_at,
        responses:responses,
        descr: url
      }

    end
    topics
  end
  def self.parse_thread_by_tid_page(tid, page=1)
    fname = Repo.get_forum_name_by_tid(tid,SID)
    link ="/forum/#{fname}/#{tid}.flat.#{page}"
    inserted = parse_thread(link)

    p "finished .parse_thread_by_tid_page url:#{link} inserted:#{inserted}"
  end

  def self.parse_full_thread(tid)
    fname = Repo.get_forum_name_by_tid(tid,SID)
    thr = Repo.get_thread(tid,SID)

    resps=thr[:responses]+1
    last_page, last_page_post_count = Repo.calc_last_page(resps,20)
    tpages = Repo.get_tpages(tid,SID)

    urls=[]
    for pp in 1..(last_page-1)
      urls<< "/forum/#{fname}/#{tid}.flat.#{pp}" if tpages[pp]!=20
    end
    urls<< "/forum/#{fname}/#{tid}.flat.#{last_page}" if tpages[last_page]!=last_page_post_count

    Parallel.map(urls,:in_threads=>3) do |link|
      pp = link.split('.').last.to_i
      inserted = parse_thread(link, pp)
      p "url:#{link} inserted:#{inserted}"
    end
    p "finished .parse_full_thread tid:#{tid}"

  end

  def self.parse_thread(url, page=1)

    url = "http://rsdn.org#{url}"

    tid = smid_from_url(url)

    url = convert_to_flat(url)+ page.to_s unless url.include? "flat."

    page_noko = Nokogiri::HTML(download_page(url))
    posts = get_page_posts(page_noko,tid)

    #p posts.map{|el| el[:addedby]}

    inserted = Repo.insert_posts(posts, tid,SID)
    Repo.insert_or_update_tpage(SID,tid, page, posts.size)
    Repo.update_thread_bot_date(tid,SID)

    inserted

  end


  def self.get_page_posts(page,smid)
    posts =[]

    page.css("div.msg-hdr").each do |pp|
      #p pp.next_element.to_s

      mid = pp.attr('data-msg-id').to_i
      title = pp.css('div')[0].css('span').text.strip

      td2=  pp.next_element.css('tr')[0].css('td')[2]
      uname = td2.text.strip

      uid =-1
      if not td2.css('a').empty?
        user_url = td2.css('a')[0]['href']
        uid = user_url.split('/').last
      end

      #post date
      date_str = pp.next_element.css('tr')[1].css('td')[1].text
      date = DateTime.strptime(date_str,"%d.%m.%y %H:%M")

      marks_html = pp.next_element.css('tr.rate-row > td.i.msg-rate > a')
      marks=marks_html.text.strip

      body = pp.next_element.next_element
      body.search('div.tagline').remove

      text = body.to_s


      posts <<
      {
        siteid:SID,
        mid: mid,
        tid: smid,
        first: mid == smid ? 1 : 0,
        body: text,
        title: title,
        addedby: uname,
        addeduid: uid,
        addeddate: date,
        marks:marks,
      }

    end
    posts

  end


  def self.find_user_posts(uid,sp,ep)
    url="http://rsdn.org/Forum/MsgUList.aspx?uid=98012&start=1"
  end

  def self.show_forums
    all = DB[:forums].filter(siteid:SID).all
    all.each { |f| p "#{f[:name]} #{f[:fid]}"  }
  end

  def self.add_forum(fid,fname)
    DB[:forums].insert(fid: fid, name: fname, siteid:SID,level:1, check: 1)
  end

  def self.edit_forum(fid, pfid)

    DB[:forums].where(siteid:SID, fid:fid).update(parent_fid: pfid)
  end
end

#RsnParser.parse_thread_by_tid_page(6194527)
#RsnParser.parse_forum(15)
