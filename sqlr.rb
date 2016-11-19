require_relative  'parsers/sqlr_parser'
require_relative  'cmd_helper'

#SqlrParser.parse_forum("linux")
DB = Repo.get_db

def show_forums
  all = DB[:forums].filter(siteid:SID).all
  all.each { |f| p "#{f[:name]} #{f[:fid]}"  }
end

def add_forum(fid,fname)
  DB[:forums].insert(fid: fid, name: fname, siteid:SID,level:1, check: 1)
end

def edit_forum(fid, pfid)

  DB[:forums].where(siteid:SID, fid:fid).update(parent_fid: pfid)
end

def show_tor
  t=Tor.new
  ip = t.get_current_ip_address #t.get_new_ip
  p "current tor ip #{ip}"
end

action = ARGV[0]
first = ARGV[1].to_i
second = ARGV[2].to_i

case action
when 'all'
  SqlrParser.check_forums(false)
  p "finished sql.ru :all"

  #ruby sqlr.rb df 16
when 'df'
  if true # need_parse_forum(first,6)
    SqlrParser.parse_forum(first, true)
    p "finished sql.ru :df"
  end

when 'dt'
  if need_parse_thread(first,6)
    p "downl thread tid:#{first} pages_back:#{second}"
    SqlrParser.load_thread(first, second)
    p "finished thread tid:#{first} pg:#{second}"
  end
end
