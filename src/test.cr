require "./discord"

client = Discord::Client.new("connector", HTTP::Client.new("wss://discordapp.gg"), "", "Bot MjM0MDUwNDQ4ODE2OTk2MzYz.CwS8kg.2vGKfGA5-pKzxyOpIkSvSzXR9o8")
client.botLogin
client.on_message_create do |payload|
    logInfo("Message recieved: #{payload.content}")
end
client.connect
