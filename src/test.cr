require "./discord"

client = Discord::Client.new("regular token here", "Bot token here")
client.botLogin
client.on_message_create do |payload|
    logInfo("Message recieved: #{payload.content}")
end
client.connect