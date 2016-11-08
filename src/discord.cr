require "http"
require "json"
require "colorize"
require "fiber"
require "random"
require "math"
require "./gateway"

def logInfo(text : String)
    puts "[INFO]".colorize(:yellow).toggle(true).to_s + " :: " + text + "\r\n"
end

def logWarning(text : String)
    puts "[WARNING]".colorize(:light_red).toggle(true).to_s + " :: " + text + "\r\n"
end

def logFatal(text : String)
    puts "[!FATAL!]".colorize(:red).toggle(true).to_s + " :: " + text + "\r\n"
end

def logSuccess(text : String)
    puts "[SUCCESS]".colorize(:green).toggle(true).to_s + " :: " + text + "\r\n"
end

def logRequest(text : String)
    puts "[REQUEST]".colorize(:light_blue).toggle(true).to_s + " :: " + text + "\r\n"
end

BASE = "https://discordapp.com"
API_BASE = BASE + "/api/v6"
GATEWAY = API_BASE + "/gateway"
USERS = API_BASE + "/users"
ME = USERS + "/@me"
REGISTER = API_BASE + "/auth/register"
LOGIN = API_BASE + "/auth/login"
LOGOUT = API_BASE + "/auth/logout"
GUILDS = API_BASE + "/guilds"
CHANNELS = API_BASE + "/channels"
APPLICATIONS = API_BASE + "/oauth2/applications"



def jsonOrText(res : HTTP::Client::Response)
    logInfo("Content-type: #{res.headers["content-type"]}")
    if res.headers["content-type"] == "application/json"
        js = JSON.parse(res.body.to_s)
        logInfo("Response: #{js}")
        return js
    end
    return res.body.to_s
end


class DSClient
    @user_agent : String
    @cg : ClientGateway
    
    def initialize(@connector : String, @session : HTTP::Client, @token : String, @bot_token : String)
        user_agent = "DiscordBot (https://github.com/Krognol/discord-cr Crystal/0.19.4)"
        @user_agent = user_agent
        @cg = ClientGateway.new
    end
    
    def getGateway
        response = HTTP::Client.get(GATEWAY)
        return Gateway.from_json(response.body)
    end

    def sendAsJson(js : String)
        return @ws.as(HTTP::WebSocket).send(js)
    end

    def getHeartbeat
        return {"op": HEARTBEAT, "d": @seq}.to_json
    end

    def identify
        payload = { "op": IDENTIFY, 
                    "d": {
                       "token": @token, 
                       "properties": {
                           "$os": "null", 
                           "$browser": "discord-cr",
                           "$device": "discord-cr",
                           "$referrer": "",
                           "$referring_domain": ""},
                        "compress": true,
                        "large_threshold": 250,
                        "v": 1}
                    }.to_json
        return self.sendAsJson(payload)
    end

    def resume
        payload = {"op": RESUME, "d": { "seq": @seq, "session_id": @session_id, "token": @token}}.to_json
        return self.sendAsJson(payload)
    end

    def messageCreate(data : JSON::Any)
        return Message.from_json(data.to_json)
    end

    def setupHeartbeats(hello : Hello)
        logInfo("Stayin' alive...'")
        stop = false
        interval = hello.interval

        spawn do
            loop do
                self.sendAsJson(getHeartbeat)
                sleep hello.interval.millisecond
            end
        end
    end

    def handleSocketMessage(msg : String)
        begin
            js = JSON.parse(msg)

            op = js["op"].as_i
            d = js["d"]
            
            if js["s"].as_i?.not_nil!
                @seq = js["s"].as_i
            end
            

            if op == RECONNECT
                logWarning("Got reconnect event; doing nothing. Reconnecting isn't implemented yet.")
                return
            end

            if op == HEARTBEAT_ACK
                return
            end

            if op == HEARTBEAT
                beat = self.getHeartbeat()
                return self.sendAsJson(beat)
            end

            if op == HELLO
                hello = Hello.from_json(js.to_s)
                setupHeartbeats(hello)
            end
            

            if op == INVALIDATE_SESSION
                @seq = 0
                @session_id = ""
                if d == true
                    @ws.as(HTTP::WebSocket).close
                    self.resume
                end
                return self.identify
            end

            if op == DISPATCH
                event = js["t"]
                handleDispatch(event, d)
            end
        rescue ex
            logFatal(ex.message.as(String))            
        end
    end

    def wsFromClient(client : DSClient, resume : Bool)
        if @token == ""
            token = @bot_token
        else
            token = client.token
        end

        ws = HTTP::WebSocket.new(getGateway.url)
        logInfo("Created a new websocket")

        if !resume
            yield self.identify
            logInfo("Sent the identify payload to create websocket connection")
            return ws
        end
    end


    def token
        return @token
    end

    def bot_token
        return @bot_token
    end

    def request(method : String, url : String, args : HTTP::Headers)
        headers = HTTP::Headers{"User-Agent" => @user_agent}

        
        if @bot_token != ""
            logInfo("bot token: #{@bot_token}")            
            headers["Authorization"] = @bot_token
            headers["Content-Type"] = "application/json"
        elsif token != ""
            headers["Authorization"] = @token
        end
            
        

        if args.has_key?("json")
            headers["Content-Type"] = "application/json"
        end    
            
        res = nil
        if args.has_key?("json")
            logRequest("Method: #{method}, Url: #{url}, Headers: #{headers.to_s}, Body: #{args["json"]}")
            res = HTTP::Client.exec(method, URI.parse(url), headers: headers, body: args["json"])
        else
            logRequest("Method: #{method}, Url: #{url}, Headers: #{headers.to_s}")
            res = HTTP::Client.exec(method, URI.parse(url), headers)
        end            
        data = jsonOrText(res)        
        if 300 > res.status_code >= 200
            logSuccess("#{method} #{url} with #{data} has returned #{res.status_code.to_s}")
            return data
        end

        if res.status_code == 429
            dat = data.as(JSON::Any)
            d = dat["retry_after"].to_s
            i = d.to_i
            i = i / 1000
            fmt = "We are being rate limited. Retrying in #{i.to_s} seconds."

            spawn do
                sleep Time.new(i.as(Int32)).second
            end
        end

        if res.status_code == 502
            logWarning("Gateway unavailable")
        end

        if res.status_code == 403
            logWarning("Access forbidden #{data}")
        elsif res.status_code == 404
            logWarning("Page not found #{data}")
        elsif res.status_code == 401
            logWarning("Unauthorized #{data}")
        else
            logWarning("Unknown HTTP error #{data}")
        end
        
    end

    def get(url : String, headers : HTTP::Headers)
        return self.request("GET", url, headers)
    end

    def put(url : String, headers : HTTP::Headers)
        return self.request("PUT", url, headers)
    end

    def patch(url : String, headers : HTTP::Headers)
        return self.request("PATCH", url, headers)
    end

    def delete(url : String, headers : HTTP::Headers)
        return self.request("DELETE", url, headers)
    end

    def post(url : String, headers : HTTP::Headers)
        return self.request("POST", url, headers)
    end

    def close
        self.session.close
    end

    def _token(token : String, bot : String)
        @token = token
        @bot_token = bot
    end

    def emailLogin(email : String, password : String)
        payload = HTTP::Headers.new
        payload["json"] = {"email": email, "password": password}.to_json
        data = self.post(LOGIN, payload).as(JSON::Any)        
        self._token(data["token"].as_s, "")
    end

    def botLogin()
        data = self.post(LOGIN, HTTP::Headers.new).as(JSON::Any)
        self._token("", data["token"].as_s)
    end

    def staticLogin(token : String, bot : String)
        old_token = @token
        old_bot = @bot_token
        self._token(token, bot)

        data = self.get(ME, nil).as(JSON::Any)
        return data
    end

    def logout
        return self.post(LOGOUT, nil)
    end

    def privateMessage(user : User)
        payload = HTTP::Headers.new
        payload["json"] = {"recipient_id": user.id}.to_json
        return self.post(ME+"/channels", payload)
    end

    def sendMessage(channel : String, msg : String, guild : String, tts : Bool)
        url = "#{CHANNELS}/#{channel}/messages"
        r = Random.new                
        payload = HTTP::Headers.new
        payload["json"] = {"content" => msg, "nonce" => r.next_int.to_s, "tts": tts}.to_json
        return self.post(url, payload)
    end

    def sendTyping(channel_id : String)
        url = "#{CHANNELS}/#{channel_id}/typing"
        return self.post(url, nil)
    end

    def on_message(msg : String)
        begin
            @cg.handleSocketMessage(msg)
        rescue ex
            logFatal(ex.message.as(String))
        end
        
    end
    
    def on_close(msg : String)
        logWarning("Connectino lcose: #{msg}")
    end

    def run(ws : HTTP::WebSocket)
        loop do
            begin
                ws.run    
            rescue ex
                logFatal(ex.message.to_s)
            end
        end
    end

    def handleDispatch(event : String, payload)
        if event == "READY"
            @seq = js["s"].as_i
            @session_id = js["session_id"].as_s
        end 
                
        if event == "MESSAGE_CREATE"
            payload = Message.from_json(d.to_json)
            call_event message_create, payload
        end

    end

    def connect        
        ws = @cg.wsFromClient(self, false) do |something|
            puts something
        end
        ws.as(HTTP::WebSocket).on_message(&->on_message(String))
        ws.as(HTTP::WebSocket).on_close(&->on_close(String))
        self.run(ws.as(HTTP::WebSocket))
    end

    macro event(name, payload)
        def on_{{name}}(&handler : {{payload}} -> )
            (@on_{{name}}_handlers ||= [] of {{payload}} -> ) << handler
        end
    end

    macro call_event(name, payload)
        @on_{{name}}_handlers.try &.each do |handler|
            begin
                handler.call({{payload}})
            rescue ex
                logFatal(ex.message.to_s)
            end
        end
    end

    event message_create, Message
end