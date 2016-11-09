require "./discord"

client = Discord::Client.new("connector", HTTP::Client.new("wss://discordapp.gg"), "", "Bot muh tokens")
client.botLogin
client.on_message_create do |payload|
    logInfo("Message recieved: #{payload.content}")
end
client.connect
