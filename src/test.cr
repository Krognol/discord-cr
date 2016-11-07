require "./discord"

client = DSClient.new("connector", HTTP::Client.new("wss://discordapp.gg"), "", "")
puts client.emailLogin("email@email.com", "P4assW0rd!_")
client.connect