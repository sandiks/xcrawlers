require 'telegram_bot'
require 'dotenv'
require_relative  '../helpers/repo'
require_relative  '../main/bct_report'

Dotenv.load('../.env')

p "start bot:::"
TOKEN = ENV["BCT_BOT_TOKEN"]
DB = Repo.get_db

def run_bot
  bot = TelegramBot.new(token: TOKEN)

  bot.get_updates(fail_silently: true) do |message|
    puts "@#{message.from.username}: #{message.text}"
    command = message.get_command_for(bot)
    fid=0
    if command.include?("forum")
      fid = command.gsub("/forum","").to_i 
      command = "/forum" 
    end
    p  "[info] cmnd: #{command} fid:#{fid}"
    text = ""

    message.reply do |reply|
      case command

      when "/start" 
        text = "this is bitcointalk forum bot, \n commands \n /list"

      when "/list"
          text = "##    /forum67 altcoin discussion 
                  ##    /forum159  Announcements (Altcoins)
                  ##    /forum72 форки(rus)  
                  ##    /forum238 bounty (Altcoins)"
      
      when "/forum"
        if fid ==0 
          text = "command 'forum' has errors"
        else
          #BctReport.gen_threads_with_stars_users(fid,'t',4)
          text = File.readlines("../report/teleg_rep_#{fid}.html").join("") rescue "file err"
        end
      
      else
        reply.text = "#{message.from.first_name}, have no idea what #{command.inspect} means."
      end
      #puts "sending #{reply.text.inspect} to @#{message.from.username}"
      reply.text = text

      reply.send_with(bot)
    end
  end
end

run_bot
#p text = File.readlines("../report/rep159.html").join("\n")
