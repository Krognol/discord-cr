require "./discord"

client = DSClient.new("connector", HTTP::Client.new("wss://discordapp.gg"), "", "Bot re4llyL0000000ngTB0tOk3n.hereAight")
puts client.botLogin
client.connect