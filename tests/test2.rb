require_relative  '../repo'

 Repo.calc_last_page(127,20)



  def self.parse_post_date(date_str)
   
    now = DateTime.now.new_offset(3.0/24)

    date = DateTime.parse(date_str) rescue DateTime.new(1900,1,1) #.new_offset(3/24.0)
    date>now ? date-1 : date
  end

  date_str = "Today at 08:16:00 PM"
  p DateTime.parse(date_str)
 # date_str = "July 21, 2017, 03:37:45 AM"
  #p parse_post_date(date_str)

    dd = {72=> 3, 159=>3,90=>2}
  p   dd[90
