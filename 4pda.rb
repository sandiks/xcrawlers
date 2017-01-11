require_relative  'parsers/4pda_parser'
require_relative  'cmd_helper'

action = ARGV[0]
first = ARGV[1].to_i
second = ARGV[2].to_i

case action
when 'check_forums'
  FpdaParser.check_forums

when 'selected'
  FpdaParser.check_selected_threads

when 'df'
  if need_parse_forum(first,10)
    FpdaParser.parse_forum(first)
    p "finished 4pda :df fid:#{first}"
  end

when 'dt'
  if true #need_parse_thread(first,10)
    second=1 if second==0
    FpdaParser.load_thread(first,second)
    p "finished lor :dt"
  end

end
