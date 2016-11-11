require "./discord"

client = Discord::Client.new("regular token here", "Bot tokensoqiwneoiuqnriuqenriwenr")
client.api.botLogin
client.on_message_create do |payload|
    case payload.content
    when ">>"
        client.api.sendMessage(payload.channel_id, "<<")
    end
end

client.on_message_delete do |payload|
    client.api.sendMessage(payload.channel_id, "Deleted message: #{payload.id}")
    puts "message deleted"
end
client.connect