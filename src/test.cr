require "./discord"

client = DSClient.new("krog", HTTP::Client.new("wss://discordapp.gg"), "", "")
puts client.emailLogin("email@email.com", "P4assw0rd!_")
puts client.sendMessage("129837147687312648", "test", "", false)