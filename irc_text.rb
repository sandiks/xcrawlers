require_relative  'repo'

def get_thread_link(sid, fname, tid)
  case sid
  when 2
    "http://rsdn.org/forum/#{fname}/#{tid}.flat.1"
  when 3
    "http://www.linux.org.ru/forum/#{fname}/#{tid}"
  when 4
    "http://www.gamedev.ru/#{fname}/forum/?id=#{tid}"
  when 6
    "http://www.sql.ru/forum/#{tid}"
  when 7
    "http://dxdy.ru/topic#{tid}.html"
  when 8
    "https://damagelab.org/index.php?showtopic=#{tid}"
  when 9
    "https://bitcointalk.org/index.php?topic=#{tid}.0"
  end
end
DB = Repo.get_db
def main

  sid =2
  fid =11

  allforums = DB[:forums].where(siteid:sid).all
  ff = allforums.where(fid: fid).first

  threads = DB[:threads].filter(siteid: sid, fid:fid).reverse_order(:updated).first(5)
  lines = threads.map { |tt| "#{tt[:title].strip} [#{get_thread_link(sid, ff[:name], tt[:tid])}]"   }
  File.write('irc_text.txt', lines.join("\n"))
end

ALL = DB[:forums].select(:siteid, :fid, :name).map { |ff| ["#{ff[:siteid]}_#{ff[:fid]}" , ff[:name]]  }.to_h
def search(ss)

  threads = DB[:threads].where(Sequel.like(:title, "%#{ss}%")).reverse_order(:updated).first(10)
  lines = threads.map do |tt|
    sid = tt[:siteid]
    fid =tt[:fid]
    key = "#{sid}_#{fid}"
    fname = ALL[key] 
    "#{tt[:title].strip} [#{get_thread_link(sid, fname, tt[:tid])}]"
  end
  File.write('irc_text.txt', lines.join("\n"))

end

#search("ubuntu")
