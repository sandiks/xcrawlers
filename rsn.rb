require_relative  'parsers/rsn_parser'
require_relative  'repo'
require_relative  'cmd_helper'

#site:2

action = ARGV[0]
first = ARGV[1].to_i
pg = ARGV[2].to_i

case action

when 'all'
  RsnParser.check_forums
  p "finished rsn :all"

when 'df'
  if need_parse_forum(first,2)
    RsnParser.parse_forum(first,true)
    p "finished rsn :df"
  else
    p "short period"
  end

when 'dt'
  if need_parse_thread(first,2)
    RsnParser.parse_full_thread(first)
    p "finished rsn :dft"
  else
    p "short period"
  end
end

#need_parse_thread(6194527)

#RsnParser.check_forums
#RsnParser.parse_forum(8,false)

#RsnParser.parse_full_thread(6194527)
#RsnParser.parse_thread_by_tid_page(6194527,1)
