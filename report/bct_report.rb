require_relative  '../helpers/helper'
require_relative  '../helpers/repo'

Sequel.split_symbols = true

class BctReport
  DB = Repo.get_db
  SID = 9
  THREAD_PAGE_SIZE =20

  def self.gen_threads_with_stars_users(fid,rank=4)
    
    from=DateTime.now.new_offset(0/24.0)-0.5
    to=DateTime.now.new_offset(0/24.0)

    title = DB[:forums].filter(siteid:SID,fid:fid).first[:title] rescue "no forum"
    uranks = DB[:users].filter(siteid:SID).to_hash(:name, :rank)
    threads = DB[:threads].filter(siteid:SID,fid:fid).to_hash(:tid, :title)
    threads_responses = DB[:threads].filter(siteid:SID,fid:fid).to_hash(:tid, :responses)

    posts = DB[:posts].join(:threads, :tid=>:tid).join(:users, :uid=>:posts__addeduid)
    .filter(Sequel.lit("posts.siteid=? and threads.fid=? and addeddate > ? and addeddate < ? and rank>=?", SID, fid, from, from+1,rank))
    .order(:addeddate)
    .select(:addeduid, :addedby, :addeddate, :posts__tid).all

    ##generate

    out = []
    out<<"[b]forum:#{title} from: #{from.strftime("%F %H:%M")}  to: #{to.strftime("%F %H:%M")}[/b]"
    out<<"------------"
    
    idx=0
    #posts.group_by{|h| h[:tid]}.sort_by{|k,v| -v.inject(0) { |sum, p| sum+(uranks[p[:addedby]]||0) } }.take(25).each do |tid, posts| 
    posts.group_by{|h| h[:tid]}.sort_by{|k,pp| -pp.group_by{|pp| pp[:addedby]}.size }.take(30).each do |tid, posts| 
            thr_title = threads[tid]||tid
            resps = threads_responses[tid]||0
            page_and_num = Repo.calc_last_page(resps+1,20)
            lpage = (page_and_num[0]-1)*40 rescue 0
            
            url = "https://bitcointalk.org/index.php?topic=#{tid}.#{lpage}"
            out<<"[b]#{idx+=1} #{thr_title}[/b] #{url}"        
             posts.group_by{|pp| pp[:addedby]}.sort_by{|uname,pp| -uranks[uname]}.each  do |uname,uposts|
              #times = uposts.map { |po|  po[:addeddate].strftime("%k:%M")}.join(",")
              posts_count = uposts.size
              out<<"[b]#{uname}[/b] [#{print_rank(uranks[uname])}] [#{posts_count} posts]"
             end 
            out<<"------------"
        
    end

    if true #active users

      posts = DB[:posts].join(:threads, :tid=>:tid).join(:users, :uid=>:posts__addeduid)
      .filter(Sequel.lit("posts.siteid=? and threads.fid=? and addeddate > ?", SID, fid, from)).select(:addeduid, :addedby).all

      out<<"*** top 15 active users *** from:#{from.strftime("%F %H:%M")}"
      posts.group_by{|pp| pp[:addedby]}.sort_by{|uname,pp| -pp.size}.take(15).each  do |uname,uposts|
        out<<"[b]#{uname}[/b] (#{uranks[uname]}) posts:#{uposts.size}"
      end
    end  

    fpath =File.dirname(__FILE__) + "/rep#{fid}.html"
    File.write(fpath, out.join("\n"))
    #system "chromium '#{fpath}'"

  end
  
  def self.print_rank(rank)
    rank==11 ? "**legend**" : "#{rank} stars"
  end

  def self.analyse_users_posts_for_thread(tid)

    from=DateTime.now.new_offset(0/24.0)-1
    uranks = DB[:users].filter(siteid:SID).to_hash(:name, :rank)

    posts = DB[:posts].join(:users, :uid=>:posts__addeduid)
    .filter(Sequel.lit("posts.siteid=? and tid=? and rank>3 and addeddate > ?", SID,tid,from)).select(:addeduid, :addedby, :addeddate, :body).all

    res=[]
    posts.group_by{|pp| pp[:addedby]}.each  do |uname,uposts|
      times = uposts.map { |pp|  "[#{pp[:addeddate].strftime("%m-%d %H:%M")} words:#{pp[:body].split.size}]"}.join(", ")
      res<<"[b]#{uname}[/b] (#{uranks[uname]}) #{times}"
    end  

    puts res

  end
  def self.top_active_users_for_forum(fid)

    title = DB[:forums].filter(siteid:SID,fid:fid).first[:title]
    from=DateTime.now.new_offset(0/24.0)-1
    uranks = DB[:users].filter(siteid:SID).to_hash(:name, :rank)

    posts = DB[:posts].join(:threads, :tid=>:tid).join(:users, :uid=>:posts__addeduid)
    .filter(Sequel.lit("posts.siteid=? and threads.fid=? and addeddate > ?", SID, fid, from)).select(:addeduid, :addedby).all

    res=[]
    res<<"most active users from: #{from.strftime("%F %H:%M")} forum:#{title}"
    posts.group_by{|pp| pp[:addedby]}.sort_by{|uname,pp| -pp.size}.each  do |uname,uposts|
      res<<"[b]#{uname}[/b] (#{uranks[uname]}) posts:#{uposts.size}"
    end  

    fpath =File.dirname(__FILE__) + "/topu#{fid}.html"
    File.write(fpath, res.join("\n"))

    puts res

  end  
end

#BctReport.gen_threads_with_stars_users(72)