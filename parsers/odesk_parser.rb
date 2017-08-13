require 'nokogiri'
require 'open-uri'
require 'parallel'
require_relative  '../repo'


class OdeskParser

  @@db = Repo.get_db

  def self.parse_categories

  end


  def self.downl(link)
    headers = { 'User-Agent' => 'Mozilla/5.0 (Windows NT 6.3; rv:36.0) Gecko/20100101 Firefox/36.0',
                "Cookie" => "session_id=9caf100f5a4c65b920602ab187ffc3af"
                }
    page_html = open(link,headers)

  end


  def self.parse_thread_page

    link = "https://www.upwork.com/jobs/?q=ruby"

    page_html = downl(link)

    page_noko = Nokogiri::HTML(page_html)
    thread_posts = page_noko.css("section.oListLite.jsSearchResults article")

    posts=[]

    thread_posts.each_with_index do|mes,indx|
      url = mes.css("a.oVisitedLink")[0]
      p title = url.text
      job_link =url['href']
      descr =mes.css("div.jsFull.isHidden").text
      #parse_job_post(job_link)

    end

    #p "inserted posts:#{posts.size}"

  end

  def self.parse_job_post(link)
    link = "https://www.upwork.com#{link}"
    page_html = downl(link)
    page_noko = Nokogiri::HTML(page_html)
    p details = page_noko.css("div.air-card-group p.break").text
    #"Oct 15, 2015 1:23:44 AM"

  end

  def self.change_rudate(date)
    mru = %w[nil янв фев мар апр мая июн июл авг сен окт ноя дек]

    dd = date.split(' ')
    dd[1] = dd[1][0..2]
    mindx = mru.index(dd[1])
    "#{dd[0]}.#{mindx}.#{dd[2]} #{dd[3]}"

    #DateTime.new(y,m,d,t.hour,t.min,0,'+3')
  end

end

act=2

OdeskParser.parse_thread_page() if act==2
