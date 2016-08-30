
require_relative  'repo'

#site:2
def need_parse_forum(fid,sid=0)
  last = Repo.get_forum_bot_date(fid,sid)
  return true if last.nil?

  now = Repo.datetime_now
  diff = ((now - last.new_offset(3/24.0))*24*60).to_i
  diff >3
end

def need_parse_thread(tid,sid=0)

  last = Repo.get_thread_bot_date(tid,sid)
  return true if last.nil?

  now = Repo.datetime_now
  diff = ((now - last.new_offset(3/24.0))*24*60).to_i
	diff >3

end
