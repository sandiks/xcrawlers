require 'nokogiri'
require 'open-uri'
require 'parallel'
require_relative  '../helpers/helper'
require_relative  '../helpers/sqlr_helper'
require_relative  '../repo'
require_relative  '../cmd_helper'

class SqlrParser

  @@db = Repo.get_db
  @@sid = 6


  def self.downl(link)
    download_page(link,true) #use tor
  end

  def self.list_forums

    link ="http://www.sql.ru/forum"

    page = Nokogiri::HTML(downl(link))
    #page = Nokogiri::HTML(File.open("allforums.html"))

    cats = page.css("table.forumTable tr") #forums

    cats.each do |cat|
      if cat.css("td").size == 6
        flink = cat.css("td:nth-child(2) a:first")[0]['href']
        ftitle = cat.css("td:nth-child(2) a:first").text
        fcode = flink.split('/').last

        fid = SqlrHelper.get_forum_id(fcode)
        if fid!=-1
          forum = {fid:fid, siteid:@@sid, title:ftitle, level:1, name:fcode }
          Repo.insert_or_update_forum(fid,@@sid)

        end
      end
      #p forum0 = {fid:10*i,siteid:@@sid, title:forums[0], level:1, name:urls[0].split('/')[2] }
      #Repo.insert_or_update_forum(forum0,3)

    end
  end

  def self.check_forums(need_parse_threads=false)

    forums = @@db[:forums].filter(siteid:@@sid,check: 1).all

    Parallel.map(forums,:in_threads=>2) do |ff|
      #forums.each do |ff|
      parse_forum(ff[:fid], need_parse_threads) if need_parse_forum(ff[:fid],@@sid)
    end
  end

  def self.parse_forum(fid, need_parse_threads=false, last_index=12)

    #fid = SqlrHelper.get_forum_id(fname)
    fname = Repo.get_forum_name(fid,@@sid)
    p "[sql.ru] parse_forum fid:#{fname}"
    fpg = 1

    link = "http://www.sql.ru/forum/#{fname}" + (fpg >1 ? "/#{fpg}" : "")

    page_noko = Nokogiri::HTML(downl(link))

    threads = page_noko.css("table.forumTable tr")

    thread_urls=[]
    page_threads =[]

    threads.drop(1).each_with_index do |tr,ind|

      url = tr.css("td.postslisttopic a")[0]['href']
      tid = url.scan(/\d+/)[0].to_i

      page_threads <<{
        fid: fid,
        tid: tid,
        title:tr.css("td.postslisttopic a")[0].text.encode('utf-8')[0..199],
        responses: tr.css("td")[3].text.to_i,
        updated: parse_date(tr.css("td")[5].text),
        #updated: tr.css("td")[5].text,
        descr:url.split('/').last[0..99],
        siteid:@@sid,
      }
      thread_urls << {tid:tid,url:url}
    end

    #page_threads.map { |tt| p tt[:updated] }
    Repo.insert_or_update_threads_for_forum(page_threads,@@sid)
    Repo.update_forum_bot_date(fid,@@sid)

    #dowmload each thread
    page_threads.each_with_index{ |thr,ind| thr[:ind] = ind }

    Parallel.each(page_threads,:in_threads=>4) do |thr|
      tid = thr[:tid]
      ind = thr[:ind]

      next if ind<3 || ind>last_index

      resps=thr[:responses]
      page = Repo.calc_page(tid,resps+1,@@sid)

      #thread_pages = @@db[:tpages].filter(siteid:@@sid, tid:tid).map([:page,:postcount])

      url_tid = thread_urls.find{|arr| arr[:tid]==tid}
      url = url_tid[:url] unless url_tid.nil?

      title = SqlrHelper.get_thread_title(url)

      if page>0 #&& page<100
        inserted =parse_thread(title, tid, page)

        p "ind:#{ind} tid:#{tid} responses:#{resps} page:#{page} inserted:#{inserted} title: #{thr[:descr]}"
      end

    end if need_parse_threads
  end


  def self.parse_thread(title, tid, page=1)

    pp = ""
    pp = "-#{page}" if page >1

    link = "http://www.sql.ru/forum/#{tid}#{pp}#{title}"
    page_noko = Nokogiri::HTML(downl(link)) rescue "error link: #{link}"

    posts = get_thread_page_posts(page_noko,tid)

    #p posts.map{|el| el[:addedby]}

    inserted = Repo.insert_posts(posts, tid,@@sid)
    Repo.insert_or_update_tpage(tid, page, posts.size,@@sid)
    Repo.update_thread_bot_date(tid,@@sid)

    #p @@db[:posts].where(siteid: 6, :tid => tid).select(:addeduid, :addedby).all

    inserted
  end


  def self.get_thread_page_posts(page,tid)
    posts =[]

    page_posts =  page.css("table.msgTable")
    res=[]

    page_posts.each do |pst|

      begin

        post = {}

        if pst.css("tr td.msgBody:first a").empty?
          addedby = pst.css("tr td.msgBody:first").text.gsub(/\r\n/, "").strip
          uid = -1
        else
          addedby =  pst.css("tr td.msgBody:first a")[0].text.strip
          uid =  pst.css("tr td.msgBody:first a")[0]['href'].gsub(/\D/, "").to_i
        end

        post[:addedby] = addedby
        post[:addeduid] = uid
        post[:body] = pst.css("tr td.msgBody:last").inner_html.strip.encode('utf-8')

        mid = post[:mid] = pst.css("tr:last td.msgFooter a:first").text.to_i
        post[:tid] = tid

        date_str = pst.css("tr:last td.msgFooter > text()").text.gsub('[]', '').gsub('|', '').strip
        #p post[:mid] #if date_str.empty?

        post[:addeddate] = parse_date(date_str)
        post[:siteid] = @@sid

        res<<post if mid!=0

      rescue
        puts "error:get_page_posts tid:#{tid} #{$!.message}"
      end
    end

    res
  end



  def self.parse_date(date_str)
    return nil if date_str.empty?
    time = Time.strptime(date_str.split(',').last.strip,"%H:%M")
    date = SqlrHelper.parse_rudate(date_str.split(',').first, time)
  end

  def self.show_forums
    all = @@db[:forums].filter(siteid:@@sid).all
    all.each { |f| p "#{f[:name]} #{f[:fid]}"  }
  end

  def self.add_forum(fid,fname)
    @@db[:forums].insert(fid: fid, name: fname, siteid:@@sid,level:1, check: 1)
  end

  def self.edit_forum(fid, pfid)

    @@db[:forums].where(siteid:@@sid, fid:fid).update(parent_fid: pfid)
  end

  def self.load_full_thread(tid,title,descr,resps=0)
    p "---loading full thread #{tid} title:#{title}"

    pages = @@db[:tpages].filter(siteid:6, tid:tid).to_hash(:page,:postcount)
    pages.sort.select { |pp|  pp[1]==25  }
    thread =  @@db[:threads].first(siteid:@@sid, tid:tid)

    resps =  thread[:responses] rescue 0 if resps ==0
    descr =  thread[:descr] rescue "" if title.empty?

    last = Repo.calc_last_page(resps,25)[0]

    Parallel.each( last.downto(1).to_a, :in_threads=>3) do |page|
      if pages[page]!=25 && page !=last
        p "load page #{page}"
        parse_thread("", tid, page)
      end
    end
    check_if_thread_exist(16,tid,title,descr,resps)
  end

  def self.check_if_thread_exist(fid,tid,title,descr,resps=0)
    tt = Repo.get_thread(tid,@@sid)
    return unless tt.nil?

    resps = @@db[:posts].filter(siteid:@@sid,tid:tid).count if resps ==0
    last = @@db[:posts].filter(siteid:@@sid,tid:tid).order(:addeddate).last[:addeddate]
    threads = []

    threads <<{
      fid: fid,
      tid: tid,
      title:title,
      responses: resps,
      updated: last,
      descr:descr,
      siteid:@@sid,
    }
    Repo.insert_or_update_threads_for_forum(threads,@@sid)
  end

end

#SqlrParser.parse_forum(16,true,20)
#p Repo.calc_page(1212142,182,6)
#SqlrParser.parse_thread("",1145993,1)

def load_full_thread
  url = "http://www.sql.ru/forum/1145993-807"
  title = ""

  tid,pg = SqlrHelper.get_tid_pg(url)
  p "tid:#{tid} pg:#{pg}"
  descr = SqlrHelper.get_thread_title(url)

  resps = pg.to_i * 25 +1
  SqlrParser.load_full_thread(tid,title,descr,resps)
end
#load_full_thread


def show_tor
  t=Tor.new
  ip = t.get_current_ip_address #t.get_new_ip
  p "current tor ip #{ip}"
end
#show_tor