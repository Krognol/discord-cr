require "./discord"

client = Discord::Client.new("regular token here", "Bot muht0000k.3ns")
client.api.botLogin
client.on_message_create do |payload|
    logInfo("Message recieved: #{payload.content}")
    if payload.content.starts_with?(">>")
        client.api.sendMessage(payload.channel_id, "<<")
    end
end

client.on_message_delete do |payload|
    client.api.sendMessage(payload.channel_id, "Deleted message: #{payload.id}")
end
client.connect