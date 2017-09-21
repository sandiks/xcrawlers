require_relative  '../parsers/bct_parser'
require_relative  'cmd_helper'
require_relative  'bct_report'
require_relative  '../parsers/helpers/bct_helper'

action = ARGV[0]
first = ARGV[1].to_i
second = ARGV[2].to_i
third = ARGV[3].to_i

##    159  Announcements (Altcoins)
##    67 altcoin discussion
##    72 форки  
##    238 bounty (Altcoins)

case action

##parser
when 'check_forums';    BCTalkParser.check_forums(first) #pages_back
when 'selected';        BCTalkParser.check_selected_threads
when 'parse_time';      BCTalkParser.downl_forum_pages_for_time(first,1,second)
when 'parse_f_p_h';     BCTalkParser.downl_forum_pages_for_time(first,second,third)
when 'parse_forum';     BCTalkParser.parse_forum(first,second,true) #if true #need_parse_forum(first,9)
when 'parse_forum_diff2'; BCTalkParser.set_opt({thread_posts_diff:2,rank:2}).parse_forum(first,second,true) # fid page need_dowl
##report
when 'repf';            BctReport.gen_threads_with_stars_users(first,'f', second) ##ruby bctalk.rb rep 159 f|t
when 'rept';            BctReport.gen_threads_with_stars_users(first,'t', second) ##ruby bctalk.rb rep 159 f|t
when 'bounty';          BctReport.print_grouped_by_bounty(first) 
when 'topu';            BctReport.top_active_users_for_forum(first) ##ruby bctalk.rb topu 159
when 'thread_users';    BctReport.analyse_users_posts_for_thread(first) 
when 'clean_err';       File.write('BCT_THREADS_ERRORS', '') 
when 'h';               p "1 bitcoin discussion 67 altcoins discussion, 159 Announcements (Altcoins) 72 форки 238 bounty (Altcoins)" 
  
when 'parse_thr'
  if true #need_parse_thread(first,9)
    second=1 if second==0
    BCTalkParserHelper.load_thread(first,second) #tid, pages_back
  end

end


#BCTalkParser.test_detect_last_page_num(1923323,pg)
#BCTalkParser.load_thread(996518,5)