require 'sequel'

pg_db = Sequel.connect('postgres://postgres:12345@localhost:5432/fbot')
mysql_db = Sequel.connect(:adapter => 'mysql2',:host => 'localhost',:database => 'fbot',:user => 'root')

tids = pg_db[:threads].filter(siteid:6, fid:16).map(:tid)
recs = pg_db[:posts].filter(siteid:6, tid:tids[0..1000]).all
p "pg: size#{recs.size} tids:#{tids.size}"

#recs.group_by { |rr| rr[:name] }.each { |k,v| p [k,v] if v.size>1  }
#p recs = recs.select { |rr| rr[:name]=='' }

exit
mysql_db.transaction do
  psize=5000
  (0..recs.size/psize).each do |pp|
    p "page:#{pp}"
    #mysql_db[:posts].multi_insert recs[pp*psize..(pp+1)*psize-1]
  end
end

mysql_db.transaction do
  from = 6000
  to =from+50000
  recs[from+1..to].each do |rr|
    mysql_db[:threads].insert rr
  end

end if false
