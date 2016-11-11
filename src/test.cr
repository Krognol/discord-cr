require "./discord"
PREFIX = ">>"

def help()
    "```Fuck you <3```"
end
client = Discord::Client.new("regular token here", "Bot tokens?? in MY discord bot? it's more likely than you think!")
client.botLogin
client.on_message_create do |message|
    case message.content
    when .starts_with?(PREFIX+"help")
        client.sendMessage(message.channel_id, help())
    end
end

client.connect