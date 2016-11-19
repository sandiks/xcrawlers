require 'sequel'
Sequel.datetime_class = DateTime

class Repo

  #DB = Sequel.connect('postgres://postgres:12345@localhost:5432/fbot')
  DB = Sequel.connect(:adapter => 'mysql2',:host => 'localhost',:database => 'fbot',:user => 'root')

  def self.get_db
    DB
  end

  def self.datetime_now
    DateTime.now.new_offset(3/24.0)
  end

  def self.get_forum_name(fid,sid=0)
    ff = DB[:forums].where(siteid:sid, fid: fid).first
    lev1 = ff[:name]
  end


  def self.get_forum_name_by_tid(tid,sid=0)
    return if sid==0

    thr = DB[:threads].where(siteid:sid, tid: tid).first
    if not thr.nil?
      ff = DB[:forums].where(siteid:sid, fid: thr[:fid]).first
      ff[:name]
    end
  end

  def self.update_forum_bot_date(fid,sid=0)
    rec = DB[:forums].filter(siteid:sid, fid: fid)
    rec.update(:bot_updated => datetime_now)
  end

  def self.get_forum_bot_date(fid,sid=0)
    rec = DB[:forums].filter(siteid:sid, fid: fid)
    rec.first[:bot_updated] #.new_offset(3/24.0)
  end


  def self.insert_forums(forums,sid=0)

    count=0
    DB.transaction do

      exist = DB[:forums].filter(siteid:sid).map(:fid)

      forums.each do |ff|
        begin
          if not exist.include? ff[:fid]
            DB[:forums].insert(ff)
            count+=1
          end
        rescue =>ex
          puts "[error fid:#{ff[:fid]}] #{ex.message}"
        end

      end

    end

    count
  end

  #####thread
  def self.get_thread_bot_date(tid,sid=0)
    rec = DB[:threads].filter(siteid:sid, tid: tid)
    rec.first[:bot_updated].new_offset(3/24.0)
  end

  def self.get_thread(tid,sid=0)
    return if sid==0
    thr = DB[:threads].first(siteid:sid, tid: tid)
  end

  def self.insert_or_update_forum(forum,sid=0)
    rec = DB[:forums].where(siteid:sid, fid: forum[:fid])

    if 1 != rec.update(:name => forum[:name])
      DB[:forums].insert(forum)
    end
  end

  def self.update_thread_bot_date(tid,sid=0)
    rec = DB[:threads].filter(siteid:sid, tid: tid)
    rec.update(:bot_updated => datetime_now)
  end

  def self.get_thread_bot_date(tid,sid=0)
    rec = DB[:threads].filter(siteid:sid, tid: tid)
    rec.first[:bot_updated]
  end

  def self.insert_posts(posts,threads_id,sid=0)
    count=0
    DB.transaction do

      exist = DB[:posts].filter(siteid:sid, tid: threads_id).map(:mid)
      posts.each do |pp|
        begin

          if not exist.include? pp[:mid]
            DB[:posts].insert(pp)
            count+=1
          end
        rescue =>ex
          puts "[error mid:#{pp[:mid]}] #{ex.message} tid:#{threads_id}"
        end

      end

    end

    count
  end


  def self.insert_threads(threads,sid=0)

    count=0
    DB.transaction do

      exist = DB[:threads].filter(siteid:sid).map(:tid)

      threads.each do |ff|
        begin
          if not exist.include? ff[:tid]
            DB[:threads].insert(ff)
            count+=1
          end
        rescue =>ex
          puts "[error tid:#{ff[:tid]}] #{ex.class}"
        end
      end
    end
    count
  end

  def self.insert_or_update_threads_for_forum(threads,sid=0, full_update=false)

    count=0
    DB.transaction do

      threads.each do |tt|
        begin

          rec = DB[:threads].filter(siteid:sid, tid: tt[:tid])
          upd_result = if full_update 
           rec.update(fid:tt[:fid], title:tt[:title], responses: tt[:responses], updated: tt[:updated])
          else 
            rec.update(responses: tt[:responses], updated: tt[:updated])
          end

          if upd_result != 1
            DB[:threads].insert(tt)
          end

        rescue =>ex
          puts "[error:insert_or_update_threads_for_forum tid:#{tt[:tid]}] #{ex.message}"
        end
      end
    end
    count
  end

  def self.insert_users(users,sid=0)

    count=0
    DB.transaction do

      exist = DB[:users].filter(siteid:sid).map(:name)

      users.each do |us|
        begin
          if not exist.include? us[:name]
            DB[:users].insert(us)
            count+=1
          end
        rescue =>ex
          puts "[error uid:#{us[:name]}] #{ex.class}"
        end

      end

    end

    count
  end
  def self.get_psize(sid=0)
    posts_on_page_sites=[0,20,20,50,20,20,25,77,88,99,20]
    posts_on_page_sites[sid]
  end

  def self.get_tpages(tid,sid=0)
    DB[:tpages].filter(siteid:sid, tid:tid).to_hash(:page,:postcount)
  end

  def self.calc_page(tid,curr_responses,sid=0)

    page_size = get_psize(sid)

    last_page_with_post_count = calc_last_page(curr_responses, page_size)

    last_page = last_page_with_post_count[0]
    last_posts_count = last_page_with_post_count[1]

    db_last_posts_count = DB[:tpages].filter(siteid:sid, tid:tid, page:last_page).map(:postcount).first||0

    all_pages=(1..last_page-1).to_a

    new_posts = true
    new_posts = db_last_posts_count<last_posts_count ||(db_last_posts_count>last_posts_count)

    page =0
    if not new_posts

      pages_count = DB[:tpages].filter(siteid:sid, tid:tid).map([:page,:postcount])

      pages_less50 = pages_count.select{|p| p[1]!=page_size && p[0]<last_page}.map { |p| p[0] }
      pages50 = pages_count.select{|p| p[1]== page_size && p[0]<last_page}.map { |p| p[0] }

      if pages_count.empty?
        page= last_page

      elsif not pages_less50.empty?
        page = pages_less50.max
      elsif
        page= (all_pages-pages50).max||0
      end

    else
      page = last_page
    end

    page

  end

  def self.calc_last_page(responses, page_size=50)
    return [1,1] if responses == 0

    post_count = (responses)%page_size
    post_count =page_size if post_count ==0

    page = (responses)/page_size+1
    page-=1 if post_count==page_size

    [page,post_count]
  end

  def self.insert_or_update_tpage(tid,page,count,sid=0)
    return if page==0 || sid==0

    #update table[tpages] with post count on page
    rec = DB[:tpages].where({siteid:sid, tid:tid, page:page })
    
    #p "update tpage #{rec.sql}"
    upd =rec.update(postcount:count)

    if 1 != upd 
      DB[:tpages].insert({siteid:sid, tid:tid, page:page, postcount:count})
    end
  end

end
