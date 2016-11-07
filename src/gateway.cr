require "json"
require "http"
require "./discord"
require "./channels"

DISPATCH           = 0
HEARTBEAT          = 1
IDENTIFY           = 2
PRESENCE           = 3
VOICE_STATE        = 4
VOICE_PING         = 5
RESUME             = 6
RECONNECT          = 7
REQUEST_MEMBERS    = 8
INVALIDATE_SESSION = 9
HELLO              = 10
HEARTBEAT_ACK      = 11
GUILD_SYNC         = 12

class Gateway
    JSON.mapping({
        url: {type: String}
    })
end

class Heartbeat
	JSON.mapping({
		op: {type: Int32},
		d: {type: Int32}
    })

	def initialize(@op : Int32, @d : Int32)
	end
end

class HearbeatACK
	JSON.mapping({
		op: {type: Int32}
    })
end

class Hello
	JSON.mapping(
		hearbeat_interval: Int32,
		_trace: Array(String)
    )	

    def interval
        return @hearbeat_interval
    end
end

class ClientGateway
    def getGateway()
        response = HTTP::Client.get(GATEWAY)
        return Gateway.from_json(response.body)
    end

    def sendAsJson(js : String)
        yield @ws.as(HTTP::WebSocket).send(js)
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
        self.sendAsJson(payload) do |js|
            yield js
        end
    end

    def resume
        payload = {"op": RESUME, "d": { "seq": @seq, "session_id": @session_id, "token": @token}}.to_json
        self.sendAsJson(payload) do |js|
            yield js
        end
    end

    def messageCreate(data : JSON::Any)
        return Message.from_json(data.to_json)
    end

    def keepAlive(hello : Hello)
        stop = false
        interval = hello.interval

        while !stop
            begin
                data = self.getHeartbeat
                self.sendAsJson(data) do |beat|
                    yield beat
                end
            rescue ex
                stop = true
            end
        end
    end

    def handleSocketMessage(msg : String)
        msg = msg.lstrip        
        begin
            js = JSON.parse(msg)

            op = js["op"].as_i
            d = js["d"]
            if js["s"].as_i? != nil
                @seq = js["s"].as_i
            end
            

            if op == RECONNECT
                logWarning("Got reconnect event; doing nothing. Reconnecting isnt' implemented yet.'")
                return
            end

            if op == HEARTBEAT_ACK
                return
            end

            if op == HEARTBEAT
                beat = self.getHeartbeat()
                self.sendAsJson(beat) do |beat|
                    yield beat
                end
                return
            end

            if op == HELLO
                hello = Hello.from_json(js.to_s)
                spawn do
                    self.keepAlive(hello) do |a|
                        logInfo(a.to_s)
                    end
                end
                return
            end

            if op == INVALIDATE_SESSION
                @seq = 0
                @session_id = ""
                if d == true
                    yield @ws.as(HTTP::WebSocket).close
                    self.resume do |res|
                        yield res
                    end
                    
                end
                self.identify do |ident|
                    yield ident
                end
                
                return
            end

            if op == DISPATCH
                event = js["t"]

                if event == "READY"
                    @seq = js["s"].as_i
                    @session_id = js["session_id"].as_s
                end 
                
                if event == "MESSAGE_CREATE"
                    yield self.messageCreate(d)
                end

                return
            end
        rescue ex
            logFatal(ex.message.as(String))            
        end
    end

    def wsFromClient(client : DSClient, resume : Bool)
        @token = client.token
        gateway = getGateway
        @ws = HTTP::WebSocket.new(gateway.url)
        logInfo("Created a new websocket")
        if !resume
            self.identify do |ident|
                yield ident
                logInfo("Sent the identify payload to create websocket connection")
                return @ws
            end
        end
    end

    def initialize
        @token = ""
        @seq = 0
        @session_id = ""
    end
end