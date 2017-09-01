require_relative  '../parsers/lor_parser'
require_relative  'cmd_helper'

action = ARGV[0]
first = ARGV[1].to_i
pg = ARGV[2].to_i

case action
when 'all'
  LORParser.check_forums(false)

when 'df'
  if need_parse_forum(first,3)
    p "download lor forum fid=#{first}"
    LORParser.parse_forum(first)
    p "finished lor :df fid:#{first}"
  end

when 'dt'
  if need_parse_thread(first,3)
    p "downl thread tid:#{first} pg:#{pg}"
    LORParser.parse_thread(nil, first, pg)
    p "finished lor :dt"
  end

end

act=0

LORParser.parse_forum(110, true) if act==2

LORParser.parse_thread(nil,11960997) if act==3
