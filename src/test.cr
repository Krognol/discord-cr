require "./discord"

client = DSClient.new("krog", HTTP::Client.new("wss://discordapp.gg"), "", "")
puts client.emailLogin("timgabe@gmail.com", "G0disD3ad!")
puts client.sendMessage("214858616140857355", "test kekers", "", false)