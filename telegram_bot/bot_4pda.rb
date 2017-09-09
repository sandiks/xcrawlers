require 'telegram/bot'
require_relative  '../repo'


#t.me/The4PDABot
TOKEN = '.secret'

DB = Repo.get_db
def run_bot

  p "start bot"

  Telegram::Bot::Client.run(TOKEN) do |bot|
    bot.listen do |message|
      case message.text

      when '/start'
        bot.api.sendMessage(chat_id: message.chat.id, text: "this is 4pda bot, \n commands \n /top")

      when '/top'
        p "[req - top] user: #{message.from.first_name}"

        threads = DB[:threads].filter(siteid:10,bot_tracked: 1).exclude(fid:287).order(:title).all

        urls  = threads.map do |tt|
          page = tt[:responses]/20+1
          pp = "&st=#{(page-1)*30}" if page >1

          #link = "<a href='http://4pda.ru/forum/index.php?showtopic=#{tt[:tid]}#{pp}'>#{tt[:title]}</a>"
          link = " #{tt[:title]} - http://4pda.ru/forum/index.php?showtopic=#{tt[:tid]}#{pp} "
          #URI.escape(link)
        end

        text = urls.join("\n")
        bot.api.sendMessage(chat_id: message.chat.id, text: text)

      when '/list'
        p "[req] user: #{message.from.first_name}"
        titles = DB[:forums].filter(siteid:10, check:1).map(:title)
        text = titles.join("\n")
        bot.api.sendMessage(chat_id: message.chat.id, text: text)

      when '/stop'
        bot.api.sendMessage(chat_id: message.chat.id, text: "Bye, #{message.from.first_name}")
      end
    end
  end

end


def test
  titles = DB[:forums].filter(siteid:10, check:1).map(:title)
  p text = titles.join('\n')
end

def test2
  p "test2"

  threads = DB[:threads].filter(siteid:10,bot_tracked: 1).exclude(fid:287).order(:title).all

  urls  = threads.map do |tt|
    page = tt[:responses]/20+1
          pp = "&st=#{(page-1)*30}" if page >1

          link = "<a href='http://4pda.ru/forum/index.php?showtopic=#{tt[:tid]}#{pp}''>#{tt[:title]}</a>"
      URI.escape(link)

  end

  p text = urls.join("\n")
end

run_bot
#test2
