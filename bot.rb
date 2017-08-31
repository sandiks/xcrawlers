require 'sequel'
require_relative  'parsers/rsn_parser'
require_relative  'parsers/lor_parser'
require_relative  'parsers/sqlr_parser'
require_relative  'parsers/gamedev_parser'
require_relative  'parsers/dxdy_parser'
require_relative  'parsers/damagelab_parser'
require_relative  'parsers/btc_parser'
require_relative  'parsers/4pda_parser'
require_relative  'repo'

DB = Repo.get_db

def add_site(sid,sname)
  DB[:sites].insert(id: sid, name: sname)
end

def self.add_forum(fid,fname)
  DB[:forums].insert(fid: fid, name: fname)
end

#add_site(3,"linux.org.ru")
#add_site(4,"gamedev.ru")

site = ARGV[0]

case site
when 'all'
  RsnParser.check_forums 
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

end

p "--finished"
#BCTalkParser.parse_forum(128)
#SqlrParser.check_forums
#SqlrParser.load_thread(1239274,5)