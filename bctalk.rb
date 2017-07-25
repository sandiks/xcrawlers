require_relative  'parsers/bct_parser'
require_relative  'cmd_helper'
require_relative  'report/bct_report'

action = ARGV[0]
first = ARGV[1].to_i
second = ARGV[2].to_i

##67 altcoin discussion
##72 форки
##159  Announcements (Altcoins)
case action

when 'check_forums';    BCTalkParser.check_forums(first) #pages_back
when 'selected';        BCTalkParser.check_selected_threads

when 'df'
  if true#need_parse_forum(first,9)
    BCTalkParser.parse_forum(first,second,true) # ruby bctalk.rb df 159 1
  end

when 'dt'
  if true #need_parse_thread(first,9)
    second=1 if second==0
    BCTalkParser.load_thread(first,second) #tid, pages_back
  end

when 'rep';        BctReport.gen_threads_with_stars_users(first) ##ruby bctalk.rb rep 159

end

act=-1

case act
when 4; BCTalkParser.parse_thread_page(1899734,41)
when 5; BCTalkParser.test_detect_last_page_num(1923323,pg)
when 6; BCTalkParser.load_thread(996518,5)
when 7; BCTalkParser.load_thread_par_from_start(996518)
else
  p "run BCTalkParser parser"
end