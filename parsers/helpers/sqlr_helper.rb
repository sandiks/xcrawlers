require 'nokogiri'

ENCODING =  'WINDOWS-1251'

class SqlrHelper

  def self.parse_rudate(date,t)
    mru = %w[nil янв фев мар апр май июн июл авг сен окт ноя дек]

    dd = date.split(' ')

    if dd.size>2 && mru.include?(dd[1])

      d = dd[0].to_i
      m = mru.index(dd[1])
      y = dd[2].to_i
      y = 1900+y if y>90 && y<=99 
      y = 2000+y if y<90 

    else
      date = dt_now
      if dd[0].strip == "вчера"
        date = date - 1
      end

      y,m,d = date.year , date.month , date.day
    end

    DateTime.new(y,m,d,t.hour,t.min,0,'+3')
  end

  def self.dt_now(offset=3)
    DateTime.now.new_offset(offset/24.0)
  end


  def self.get_tid_pg(url)
    in1 = url.index('forum/')
    in2 = url.index('/', in1+6)
    in2 =  in2.nil? ? url.size : in2-1

    arr =  url[in1+6..in2].split('-')

    return arr[0], 1 if arr.size == 1
    return arr[0], arr[1] if arr.size == 2

  end
  def self.calc_pgnum_count(all)

    pgnum = (all-1)/25+1
      count = all%25 == 0 ? 25 : all%25
      return pgnum , count
    end

    def self.get_thread_title(url)

      in1 = url.index('forum/')
      in2 = url.index('/', in1+6)
      in2 =  in2.nil? ? url.size : in2-1
      url[in2+1..-1]

    end

    def self.get_tid_pg2(url)
      tid, pg = url.scan(/\d+.[\d|a]+/)[0].split("-")
    pg = 1  if pg.nil?
    return tid, pg
  end

  def self.detect_quote_to(text, tuser_names)

    tuser_names.each do |tuser|
      if text.start_with?("#{tuser},<br>")
        return tuser
      end
    end

    ptext = Nokogiri::HTML(text)

    ptext.css('table').each do |node|
      if not node.ancestors('table').any?
        whom = node.xpath('tr/th').text.strip
        return whom
      end
    end
  end

  def self.get_forum_id(name)
    case name
    when "pt";          16
    when "pt-archive";  16
    when "microsoft-sql-server"; 1
    when "interbase";            2
    when "oracle";        3
    when "oracle-apex";   3001
    when "oracle-forms";  3002
    when "access";    4
    when "db2";       5
    when "mysql";     6
    when "postgresql";    7
    when "olap-dwh";      8
    when "sybase";        9
    when "informix";    10
    when "db-other";    11
    when "foxpro";      12
    when "cache";       13
    when "sqlite";      14
    when "nosql-bigdata";   15

    when "db-comparison";   21
    when "db-design";       22
    when "job";             23
    when "job-offers";      2301
    when "erp-crm";         24
    when "testing-qa";      25
    when "reporting";       26
    when "za-rubezhom";     27
    when "certification";   28
    when "hardware";        29
    when "dev-management";  291
    when "legal";           292

    when "dotnet";   30
    when "asp-net";   31
    when "ado-linq-ef-orm";   32
    when "wpf-silverlight";   33
    when "wcf-ws-remoting";   34

    when "delphi";          40
    when "cpp";             41
    when "visual-basic";    42
    when "programming";     43
    when "java";            44
    when "powerbuilder";    45
    when "ms-office";       46
    when "sharepoint";      47
    when "xml";             48

    when "php-perl";              50
    when "html-javascript-css";   51
    when "ssjs";                  5101

    when "windows";   61
    when "linux";     62
    when "other-os";  63

    when "sqlru";             70
    when "question-answer";   71

    else -1

    end
  end
end
