require_relative  '../helpers/helper'
require_relative  '../helpers/repo'
require_relative  '../helpers/page_utils'

Sequel.split_symbols = true

class BctReport
  DB = Repo.get_db
  SID = 9
  THREAD_PAGE_SIZE =20

  def self.gen_threads_with_stars_users(fid, type='f', time =12)
    rank =3
    time =6 if time==0
    
    from=DateTime.now.new_offset(0/24.0)-time/24.0
    to=DateTime.now.new_offset(0/24.0)

    title = DB[:forums].filter(siteid:SID,fid:fid).first[:title] rescue "no forum"
    uranks = DB[:users].filter(siteid:SID).to_hash(:name, :rank)
    threads = DB[:threads].filter(siteid:SID,fid:fid).to_hash(:tid, :title)
    threads_responses = DB[:threads].filter(siteid:SID,fid:fid).to_hash(:tid, :responses)

    posts = DB[:posts].join(:threads, :tid=>:tid).join(:users, :uid=>:posts__addeduid)
    .filter(Sequel.lit("posts.siteid=? and threads.fid=? and addeddate > ? and addeddate < ? and rank>=?", SID, fid, from, from+1,rank))
    .order(:addeddate)
    .select(:addeduid, :addedby, :addeddate, :posts__tid, :rank).all

    p "forum:#{title} posts:#{posts.size}"

    ##generate
    is_forum = type =='f' 
    bold =  is_forum ? "[b]" : "**"
    bold_end = is_forum ? "[/b]" : "**"


    out = []
    
    is_forum ? out<<"#{bold}forum: #{title}#{bold_end}" : out<<"Most babble threads from \"#{bold}#{title}#{bold_end}\""
    out<<"#{bold}#{from.strftime("%F %H:%M")}  -  #{to.strftime("%F %H:%M")}#{bold_end}"
    out<<"------------"
    
    idx=0
    #posts.group_by{|h| h[:tid]}.sort_by{|k,v| -v.inject(0) { |sum, p| sum+(uranks[p[:addedby]]||0) } }.take(25).each do |tid, posts| 
    posts.group_by{|h| h[:tid]}.sort_by{|k,pp| -pp.group_by{|pp| pp[:addedby]}.size }.take(25).each do |tid, th_posts| 
            thr_title = threads[tid]||tid
            resps = threads_responses[tid]||0
            page_and_num = PageUtil.calc_last_page(resps+1,20)
            lpage = (page_and_num[0]-1)*40 rescue 0
            
            url = "https://bitcointalk.org/index.php?topic=#{tid}.#{lpage}"

            count = th_posts.size
            out<<"#{bold}#{idx+=1} #{thr_title}#{bold_end} #{url}"
            count11=100* th_posts.count{|pp| pp[:rank]==11}/count.to_f  
            count5 =100* th_posts.count{|pp| pp[:rank]==5}/count.to_f  
            count4 =100* th_posts.count{|pp| pp[:rank]==4}/count.to_f  
            count3 =100* th_posts.count{|pp| pp[:rank]==3}/count.to_f 
            if is_forum
              out<< "count:#{count} \n  legend: #{'%.1f' %count11}% \n 5 stars #{'%.1f' %count5}% \n 4 stars #{'%.1f' %count4}% \n 3 stars #{'%.1f' %count3}%"  
            else
              out<< "count:#{count} legend: #{'%.1f' %count11}%  5 stars #{'%.1f' %count5}% 4 stars #{'%.1f' %count4}%  3 stars #{'%.1f' %count3}%"  
            end

             th_posts.group_by{|pp| pp[:addedby]}.sort_by{|uname,pp| -pp[:rank]}.each  do |uname,uposts|
              out<<"#{bold}#{uname} (#{print_rank(uranks[uname])})#{bold_end} [#{uposts.size} posts]"
             end if false
            out<<"------------"
        
    end

    if false #is_forum  #active users
      top = 25

      posts = DB[:posts].join(:threads, :tid=>:tid).join(:users, :uid=>:posts__addeduid)
      .filter(Sequel.lit("posts.siteid=? and threads.fid=? and addeddate > ?", SID, fid, from)).select(:addeduid, :addedby).all

      out<<"**top #{top} active users** from:#{from.strftime("%F %H:%M")}"
      posts.group_by{|pp| pp[:addedby]}.sort_by{|uname,pp| -pp.size}.take(top).each  do |uname,uposts|
        out<<"#{bold}#{uname}#{bold_end} (#{uranks[uname]}) posts:#{uposts.size}"
      end
    end 

    rep_name = is_forum ? "for_rep" : "teleg_rep" 

    fpath ="../report/#{rep_name}_#{fid}.html"
    File.write(fpath, out.join("\n"))
    #system "chromium '#{fpath}'"

  end
  
  def self.print_rank(rank)
    rank==11 ? "**legend**" : "#{rank}"
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

  def self.print_users_bounty(fid)

    title = DB[:forums].filter(siteid:SID,fid:fid).first[:title]
    from=DateTime.now.new_offset(0/24.0)-0.6

    unames = DB[:users].filter(siteid:SID).to_hash(:uid, [:name,:rank])
    user_bounties = DB[:bct_user_bounty].to_hash(:uid, :bo_name)

    posts = DB[:posts].join(:threads, :tid=>:tid)
    .join(:users, :uid=>:posts__addeduid)
    .filter(Sequel.lit("posts.siteid=? and threads.fid=? and addeddate > ? and rank>2", SID, fid, from))
    .select(:addeduid, :addedby).all

    res=[]
    res<<"top 25 users boubty from: #{from.strftime("%F %H:%M")} forum:#{title}"
    posts.group_by{|pp| pp[:addeduid]}.select{|uid,pp| user_bounties[uid]}
    .sort_by{|uid,pp| -unames[uid][1]}.each do |uid,uposts|
      res<<"[b]#{unames[uid][0]}[/b] (#{unames[uid][1]}) #{user_bounties[uid]}"
    end  

    fpath =File.dirname(__FILE__) + "/bounties#{fid}.html"
    File.write(fpath, res.join("\n"))

  end   
  def self.print_groupped_by_bounty(fid)

    title = DB[:forums].filter(siteid:SID,fid:fid).first[:title]
    from=DateTime.now.new_offset(0/24.0)-0.6

    unames = DB[:users].filter(siteid:SID).to_hash(:uid, [:name,:rank])
    user_bounties = DB[:bct_user_bounty].to_hash(:uid, :bo_name)

    posts = DB[:posts].join(:threads, :tid=>:tid)
    .join(:users, :uid=>:posts__addeduid)
    .filter(Sequel.lit("posts.siteid=? and threads.fid=? and addeddate > ? and rank>2", SID, fid, from))
    .select(:addeduid).all

    res=[]
    res<<"groupped by bounty  ***forum:#{title}"
    users = posts.group_by{|pp| pp[:addeduid]}.select{|uid,b_uu| user_bounties[uid]}.map { |k,v| k }
    users.group_by{|uid| user_bounties[uid].gsub(' ', '')}.sort_by{|bname,uu| -uu.size}.each do |bname, uids|
      break if uids.size<2

      res<<" -------"
      res<<" ---[b]#{bname}[/b] #{uids.size}"
      res<< uids.each_slice(5).to_a.map do |sub_uids| 
        sub_uids.map { |uid| "#{unames[uid][0]}(#{unames[uid][1]})"}.join(',')
      end

    end  

    fpath =File.dirname(__FILE__) + "/bounties#{fid}.html"
    File.write(fpath, res.join("\n"))

  end        
end

#BctReport.gen_threads_with_stars_users(72)