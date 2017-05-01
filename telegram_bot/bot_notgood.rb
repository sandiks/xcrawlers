require 'telegram_bot'

#t.me/The4PDABot
token = '360749711:AAF4PPtM12ab9w_egOoQ0dvDRFe6kghV6F4'

p "start bot:::"
bot = TelegramBot.new(token: token)
bot.get_updates(fail_silently: true) do |message|
  puts "@#{message.from.username}: #{message.text}"
  command = message.get_command_for(bot)

  message.reply do |reply|
    case command
    when /greet/i
      reply.text = "Hello, #{message.from.first_name}!"
    else
      reply.text = "#{message.from.first_name}, have no idea what #{command.inspect} means."
    end
    puts "sending #{reply.text.inspect} to @#{message.from.username}"
    reply.send_with(bot)
  end
end