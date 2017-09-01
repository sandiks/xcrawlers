require_relative  'parsers/gamedev_parser'
require_relative  'cmd_helper'

action = ARGV[0]
first = ARGV[1].to_i

case action

when 'all'
  GDParser.check_forums(false)

when 'df'
  if need_parse_forum(first,4)
    #p "download lor forum fid=#{first}"
    GDParser.parse_forum(first, true)
  end

when 'dt'
  if need_parse_thread(first,4)
    GDParser.parse_thread(nil,first)
  end
end
