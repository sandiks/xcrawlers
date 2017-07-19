require_relative  'parsers/bct_parser'
require_relative  'cmd_helper'

action = ARGV[0]
first = ARGV[1].to_i
second = ARGV[2].to_i

case action
when 'check_forums'
  pages_back = first
  BCTalkParser.check_forums(pages_back)

when 'selected'
  BCTalkParser.check_selected_threads

when 'df'
  if need_parse_forum(first,9)
    BCTalkParser.parse_forum(first,second)
    p "finished bctalk :df fid:#{first}"
  end

when 'dt'
  if true #need_parse_thread(first,9)
    second=1 if second==0
    BCTalkParser.load_thread(first,second)
    p "finished bctalk :dt"
  end

end

act=action.to_i

case act
when 2; BCTalkParser.check_forums
when 3; BCTalkParser.parse_forum(72,1)
when 4; BCTalkParser.parse_thread_page(1899734,41)
when 5; BCTalkParser.test_detect_last_page_num(1923323,pg)
when 6; BCTalkParser.load_thread(996518,5)
when 7; BCTalkParser.load_thread_par_from_start(996518)
else
  p "run BCTalkParser parser"
end