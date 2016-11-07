require_relative  'parsers/4pda_parser'
require_relative  'cmd_helper'

action = ARGV[0]
first = ARGV[1].to_i
pg = ARGV[2].to_i

case action
when 'check_forums'
  FpdaParser.check_forums

when 'all'
  FpdaParser.check_selected_threads
when 'df'
  if need_parse_forum(first,10)
    p "download 4pda forum fid=#{first}"
    FpdaParser.parse_forum(first)
    p "finished 4pda :df fid:#{first}"
  end

when 'dt'
  if need_parse_thread(first,10)
    p "downl thread tid:#{first} pg:#{pg}"
    FpdaParser.load_thread(first)
    p "finished lor :dt"
  end

end
