require 'cinch'
require_relative  'repo'
require_relative  'irc_text'


bot = Cinch::Bot.new do
  configure do |c|
    c.server = "irc.freenode.org"
    c.nick = "info_bot"
    c.channels = ["#dev_forums"]
  end

  on :message, /^!last/ do |m|
    text = File.readlines("irc_text.txt").map { |ll| ll.strip  }
    text.each { |ll| m.reply ll  }
  end
  on :message, /^!s (.+)/ do |m, ss|
  	search(ss)
    text = File.readlines("irc_text.txt").map { |ll| ll.strip  }
    text.each { |ll| m.reply ll  }
  end

end

bot.start
