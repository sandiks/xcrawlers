require 'nokogiri'
require_relative  '../helpers/helper'
require_relative  '../helpers/repo'
require_relative  '../parsers/bct_parser'


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

def save_thread_title
      page_threads =[]
      page_threads << {
        fid:159,
        tid:2149614,
        #title:"🚀[ANN][PoSToken]World's First Proof-of-Stake Smart Contract Token[AIRDROP LIVE]",
        title:"[ANN][🔥PRE - ICO OPEN🔥] LUST: DECENTRALIZED SEX MARKETPLACE WITH ESCROW!",
        responses: 1,
        viewers: 1,
        updated: nil,
        siteid:SID,
      }
      #Repo.insert_or_update_threads_for_forum(page_threads,SID,true)
      Repo.insert_threads(page_threads,SID)
end

#File.open('BCT_THREADS_ERRORS', 'a') { |f| f.write("1 1\n") }
case 4

  when 1; save_thread_title()
  when 2;#BCTalkParser.parse_forum(159,1,true)
  when 3; p test_calc_arr_downl_pages(2014218)
  when 4; BCTalkParser.parse_thread_page(1438371,39)

end
