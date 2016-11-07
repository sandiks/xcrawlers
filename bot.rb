require 'sequel'
require 'rufus-scheduler'
require_relative  'parsers/rsn_parser'
require_relative  'parsers/lor_parser'
require_relative  'parsers/sqlr_parser'
require_relative  'parsers/gamedev_parser'
require_relative  'parsers/dxdy_parser'
require_relative  'parsers/damagelab_parser'
require_relative  'parsers/btc_parser'
require_relative  'parsers/4pda_parser'

#@@db = Sequel.connect('postgres://postgres:12345@localhost:5432/fbot')

def add_site(sid,sname)
  @@db[:sites].insert(id: sid, name: sname)
end

def self.add_forum(fid,fname)
  @@db[:forums].insert(fid: fid, name: fname)
end

#add_site(3,"linux.org.ru")
#add_site(4,"gamedev.ru")

site = ARGV[0]

case site
when 'all'
  RsnParser.check_forums rescue "RsnParser:error"
  LORParser.check_forums rescue "LORParser:error"
  #SqlrParser.check_forums rescue "SqlrParser:error"
  #DXDYParser.check_forums rescue "DXDYParser:error"
  #DamageLabParser.check_forums rescue "DamageLabParser:error"
  #BCTalkParser.check_forums rescue "BCTalkParser:error"

  #FpdaParser.check_selected_threads rescue "4PDAParser:error"
  FpdaParser.check_forums rescue "4PDAParser:error"
  
when 'rsn'
  RsnParser.check_forums
when 'lor'
  LORParser.check_forums
when 'gd'
  GDParser.check_forums
when 'sqlr'
  SqlrParser.check_forums
when 'dxdy'
  DXDYParser.check_forums
when 'damagelab'
  DamageLabParser.check_forums
when 'bctalk'
  BCTalkParser.check_forums
when '4pda'
  FpdaParser.check_selected_threads

when 'shedule-pt'
  # ruby bot.rb shedule-pt 60
  p "task:shedule-pt"
  period = ARGV[1]
  scheduler = Rufus::Scheduler.new
  scheduler.every "#{period}s" do
    SqlrParser.parse_forum(16,true)
    dd = DateTime.now.new_offset(3/24.0).strftime("%F %k:%M:%S ")
    p "---finished sheduler #{dd}"
  end
  scheduler.join

# ruby bot.rb dnwl-thread tid
when 'dnwl-thread'
  p "---task:dnwl-thread"
  tid = ARGV[1]
  SqlrParser.load_full_thread(tid,"","",0)
  dd = DateTime.now.new_offset(3/24.0).strftime("%F %k:%M:%S ")
  p "---finished dnwl-thread #{dd}"
end

p "--finished"
#BCTalkParser.parse_forum(128)
#SqlrParser.check_forums
