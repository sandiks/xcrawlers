require 'sequel'

pg_db = Sequel.connect('postgres://postgres:12345@localhost:5432/fbot')
mysql_db = Sequel.connect(:adapter => 'mysql2',:host => 'localhost',:database => 'fbot',:user => 'root')

recs = pg_db[:posts].filter(siteid:10).all
p "pg: size#{recs.size}"
#recs.group_by { |rr| rr[:name] }.each { |k,v| p [k,v] if v.size>1  }
#p recs = recs.select { |rr| rr[:name]=='' }


mysql_db.transaction do
 mysql_db[:posts].multi_insert recs
end  

mysql_db.transaction do
  from = 6000
  to =from+50000
  recs[from+1..to].each do |rr|
    mysql_db[:threads].insert rr
  end

end if false
