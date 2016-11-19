Sequel.migration do
  change do
    create_table(:forums) do
      Integer :siteid, :null=>false
      Integer :fid, :null=>false
      String :name
      Integer :level
      Integer :parent_fid
      String :title
      Integer :check
      DateTime :bot_updated
      String :descr
      
      primary_key [:siteid, :fid]
    end
    
    create_table(:logs) do
      String :referer
      String :path
      String :ip
      String :uagent
      DateTime :date
    end
    
    create_table(:main_forums) do
      Integer :mfid, :null=>false
      String :title
      
      primary_key [:mfid]
    end
    
    create_table(:posts, :ignore_index_errors=>true) do
      Integer :mid, :null=>false
      Integer :siteid, :null=>false
      String :body
      String :addedby, :size=>50
      Integer :addeduid
      DateTime :addeddate
      Integer :tid, :null=>false
      Integer :first, :default=>0
      String :title
      String :marks
      Integer :pnum
      
      primary_key [:mid, :siteid, :tid]
      
      index [:siteid, :tid], :name=>:indx_posts_sid_tid
    end
    
    create_table(:site_forums) do
      Integer :mfid, :null=>false
      Integer :siteid, :null=>false
      Integer :fid, :null=>false
      
      primary_key [:mfid, :siteid, :fid]
    end
    
    create_table(:sites) do
      Integer :id, :null=>false
      String :descr, :size=>100, :fixed=>true
      String :name
      
      primary_key [:id]
    end
    
    create_table(:threads, :ignore_index_errors=>true) do
      Integer :tid, :null=>false
      Integer :siteid, :null=>false
      Integer :fid, :null=>false
      String :title, :size=>200, :fixed=>true, :null=>false
      DateTime :created
      DateTime :updated
      Integer :viewers
      Integer :responses
      String :descr, :size=>100, :fixed=>true
      DateTime :bot_updated
      Integer :sticked
      Integer :bot_tracked
      
      primary_key [:tid, :siteid, :fid]
      
      index [:fid, :siteid, :tid], :name=>:indx_threads_sid_fid_tid
    end
    
    create_table(:tpages) do
      Integer :siteid, :null=>false
      Integer :tid, :null=>false
      Integer :page, :null=>false
      Integer :postcount
      
      primary_key [:siteid, :tid, :page]
    end
    
    create_table(:users) do
      String :name, :size=>50, :null=>false
      Integer :uid
      DateTime :lastposted
      Integer :siteid, :null=>false
      
      primary_key [:name, :siteid]
    end
  end
end
