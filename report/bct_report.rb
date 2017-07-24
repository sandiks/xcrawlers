require_relative  '../helpers/helper'
require_relative  '../repo'

Sequel.split_symbols = true

class Bctalk
  DB = Repo.get_db
  SID = 9
  THREAD_PAGE_SIZE =20

  def self.gen_threads_with_stars_users(fid)
    
    from=DateTime.now.new_offset(3/24.0)-1

    uranks = DB[:users].filter(siteid:9).to_hash(:name, :rank)
    threads = DB[:threads].filter(siteid:9).to_hash(:tid, :title)

    posts = DB[:posts].join(:threads, :tid=>:tid).join(:users, :uid=>:posts__addeduid)
    .filter("posts.siteid=? and threads.fid=? and addeddate > ? and addeddate < ? and rank>2", 9, fid, from, from+1)
    .order(:addeddate)
    .select(:addeduid, :addedby, :addeddate, :posts__tid).all

    ##generate

    out = []
    out<<"date [b]from: #{from.strftime("%F %H:%M")}[/b]"
    idx=0
    posts.group_by{|h| h[:tid]}.sort_by{|k,v| -v.size}.each do |tid, posts| 
            out<<"[b]#{idx+=1} #{threads[tid]||tid}[/b]"        
             posts.group_by{|pp| pp[:addedby]}.each  do |uname,uposts|
              times = uposts.map { |po|  po[:addeddate].strftime("%k:%M")}.join(",")
              out<<"#{uname} (#{uranks[uname]}) #{times}"
             end 
        
    end

     fpath =File.dirname(__FILE__) + "/rep1.html"
     File.write(fpath, out.join("\n"))
     #system "chromium '#{fpath}'"

  end
end

Bctalk.gen_threads_with_stars_users(72)