require_relative  '../parsers/satsang_parser'
require_relative  'cmd_helper'

action = ARGV[0]
first = ARGV[1].to_i
second = ARGV[2].to_i


#ruby sats.rb pf 1 2

case action
when 'pf'; SatsParser.parse_forum(first,1) # fid, page
when 'pt'; SatsParser.parse_thread_page(1,684530,1)
when 'ltp'; SatsParser.load_thread_par_from_start(1,587330,50) # 443939 587330  down thread http://offtop.ru/satsang/v1_443939__.php

when 5; SatsParser.test_detect_last_page_num(1923323,pg)
when 7; SatsParser.load_thread_par_from_start(996518)
when 8; SatsParser.check_forums
else
  p "run SatsParser parser"
  #http://offtop.ru/satsang/v1_684530__.php
  #SatsParser.calc_arr_downl_pages(684530,3,7)
end