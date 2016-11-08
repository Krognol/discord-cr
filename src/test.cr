require "./discord"

client = DSClient.new("connector", HTTP::Client.new("wss://discordapp.gg"), "", "Bot iewjtnwnrteiwurbentuiewbrth")
puts client.botLogin
client.connect
client.on_message_create do |payload|
    puts payload.content
end