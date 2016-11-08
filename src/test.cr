require "./discord"

client = DSClient.new("connector", HTTP::Client.new("wss://discordapp.gg"), "", "Bot MjM0MDUwNDQ4ODE2OTk2MzYz.CwPvgQ.ATitz-t9dVgnqWklcKAbRf3K2hE")
puts client.botLogin
client.connect
client.on_message_create do |payload|
    puts payload.content
end