require 'nokogiri'
require_relative  '../helpers/helper'
require_relative  '../repo'

DB = Repo.get_db
SID=9
THREAD_PAGE_SIZE =20
def self.test_detect_last_page_num(tid,page=1)
    p link = get_link(tid,page)
    page_html = Nokogiri::HTML(download_page(link))
    #page_html = Nokogiri::HTML(File.open("html/bctalk-tid2006833-p2.html"))

    p last = detect_last_page(page_html)
end

def self.calc_arr_downl_pages(tid,last_page,last_page_posts)
    downl_pages=[]

    p tpages = DB[:tpages].filter(siteid:SID, tid:tid).to_hash(:page,:postcount)
    downl_pages<<last_page if last_page_posts != tpages[last_page]

    (last_page-1).downto(1) do |pg|
      downl_pages<<pg if tpages[pg]!=THREAD_PAGE_SIZE 
    end

    downl_pages
end

def test_calc_arr_downl_pages(tid)
  responses = 110
  last_page_num = Repo.calc_last_page(responses+1,20)
  lpage = last_page_num[0]
  lcount = last_page_num[1]
  downl_pages=calc_arr_downl_pages(tid,lpage,lcount)
end

p test_calc_arr_downl_pages(2014218)