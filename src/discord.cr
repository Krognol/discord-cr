require "http"
require "json"
require "colorize"
require "fiber"
require "random"
require "math"
require "./**"

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

module Discord
    class Client
    include RestAPI::API
        @hold_up : Float64
        def initialize(@token : String, @bot_token : String)
            @ws = HTTP::WebSocket
            @hold_up = 1.0
            @user_agent = "DiscordBot (https://github.com/Krognol/discord-cr Crystal/0.19.4)"
            #n(self)
            #@api = RestAPI::API.new("DiscordBot (https://github.com/Krognol/discord-cr Crystal/0.19.4)", self)
        end
        
        def n(a)
            a.token
        end

        def api
            return @api.as(RestAPI::API)
        end

        def token
            return @token
        end

        def bot_token
            return @bot_token
        end

        def setupApi
            @api = RestAPI::API.new("DiscordBot (https://github.com/Krognol/discord-cr Crystal/0.19.4)", self)
        end

        def getGateway
            response = HTTP::Client.get(EndpointGateway)
            return Gateway::Gateway.from_json(response.body)
        end

        def sendAsJson(js : String)
            return @ws.as(HTTP::WebSocket).send(js)
        end

        def getHeartbeat
            return {"op": Gateway::HEARTBEAT, "d": @seq}.to_json
        end

        def identify
            token = ""
            if @bot_token != ""
                token = @bot_token
            else
                token = @token
            end
            payload = { "op": Gateway::IDENTIFY, 
                        "d": {
                        "token": token, 
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
            token = ""
            if @bot_token != ""
                token = @bot_token
            else
                token = @token
            end
            payload = {"op": Gateway::RESUME, "d": { "seq": @seq, "session_id": @session_id, "token": token}}.to_json
            return self.sendAsJson(payload)
        end

        def setupHeartbeats(hello : Gateway::Hello)
            logInfo("Stayin' alive...")
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
                
                if js["s"].as_i? != nil
                    @seq = js["s"].as_i
                end

                case op
                    when Gateway::HELLO
                        hello = Gateway::Hello.from_json(d.to_json)
                        setupHeartbeats(hello)
                    when Gateway::RECONNECT
                        wsFromClient(false)
                    when Gateway::HEARTBEAT_ACK
                        return
                    when Gateway::HEARTBEAT
                        beat = self.getHeartbeat()
                        self.sendAsJson(beat)
                    when Gateway::INVALIDATE_SESSION
                        @seq = 0
                        @session_id = ""
                        if d == true
                            @ws.as(HTTP::WebSocket).close
                            self.resume
                        end
                        self.identify
                    when Gateway::DISPATCH
                        event = js["t"]
                        handleDispatch(event.as_s, d)
                end
            rescue ex
                logFatal("Error while handling socket message: #{ex.message.to_s}\r\nPayload: #{d.to_json}")            
            end
            return
        end

        def wsFromClient(resume : Bool)
            url = URI.parse(getGateway.url)
            @ws = HTTP::WebSocket.new(host: url.host.not_nil!, path: "#{url.path}/?encoding=json&v=6", port: 443, tls: true)
            @ws.as(HTTP::WebSocket).on_message(&->on_message(String))
            @ws.as(HTTP::WebSocket).on_close(&->on_close(String))
            logInfo("Created a new websocket")

            if !resume
                self.identify
                logInfo("Sent the identify payload to create websocket connection") 
            end
        end

        def _token(token : String, bot : String)
            @token = token
            @bot_token = bot
        end

        def on_message(msg : String)
            begin
                handleSocketMessage(msg)
            rescue ex
                logFatal(ex.message.as(String))
            end
            
        end
        
        def on_close(msg : String)
            logWarning("Connection closed: #{msg}")
        end

        def waitToReconnect
            logWarning("Sleeping for #{@hold_up.to_s} seconds before trying to reconnect")

            sleep @hold_up.seconds

            @hold_up = 1.0 if @hold_up < 1.0
            @hold_up *= 1.5 if @hold_up < 120.0
            @hold_up = 115.0 + (90.0 - @hold_up) if @hold_up > 120.0
        end

        def run
            loop do
                begin
                    @ws.as(HTTP::WebSocket).run
                rescue ex
                    logFatal(ex.message.to_s)
                end
                waitToReconnect

                wsFromClient(false)
            end
        end

        def handleDispatch(event : String, data : JSON::Any)
            case event
                when "READY"
                    payload = Gateway::Ready.from_json(data.to_json)
                    call_event ready, payload
                when "RESUMED"
                    payload = Gateway::Resume.from_json(data.to_json)
                    call_event resume, payload
                when "STATUS_UPDATE"
                    payload = Gateway::StatusUpdate.from_json(data.to_json)
                    call_event status_update, payload
                when "CHANNEL_CREATE"
                    payload = Channels::Channel.from_json(data.to_json)
                    call_event channel_create, payload
                when "CHANNEL_UPDATE"
                    payload = Channels::Channel.from_json(data.to_json)
                    call_event channel_update, payload
                when "GUILD_CREATE"
                    payload = Guilds::Guild.from_json(data.to_json)
                    call_event guild_create, payload
                when "GUILD_UPDATE"
                    payload = Guilds::Guild.from_json(data.to_json)
                    call_event guild_update, payload
                when "GUILD_DELETE"
                    payload = Guilds::Guild.from_json(data.to_json)
                    call_event guild_delete, payload
                when "GUILD_BAN_ADD"
                    payload = Users::User.from_json(data.to_json)
                    call_event guild_ban_add, payload
                when "GUILD_BAN_REMOVE"
                    payload = Users::User.from_json(data.to_json)
                    call_event guild_ban_remove, payload
                when "GUILD_EMOJIS_UPDATE"
                    payload = Guilds::EmojisUpdate.from_json(data.to_json)
                    call_event guild_emojis_update, payload
                when "GUILD_INTEGRATIONS_UPDATE"
                    payload = Guilds::IntegrationsUpdate.from_json(data.to_json)
                    call_event guild_integrations_update, payload 
                when "GUILD_MEMBER_ADD"
                    payload = Guilds::GuildMember.from_json(data.to_json)
                    call_event guild_member_add, payload
                when "GUILD_MEMBER_REMOVE"
                    payload = Guilds::MemberRemove.from_json(data.to_json)
                    call_event guild_member_remove, payload
                when "GUILD_MEMBER_UPDATE"
                    payload = Guilds::MemberUpdate.from_json(data.to_json)
                    call_event guild_member_update, payload
                when "GUILD_MEMBERS_CHUNK"
                    payload = Guilds::MembersChunk.from_json(data.to_json)
                    call_event guild_members_chunk, payload
                when "GUILD_ROLE_CREATE"
                    payload = Guilds::RoleCreate.from_json(data.to_json)
                    call_event guild_role_create, payload
                when "GUILD_ROLE_UPDATE"
                    payload = Guilds::RoleUpdate.from_json(data.to_json)
                    call_event guild_role_update, payload
                when "GUILD_ROLE_DELETE"
                    payload = Guilds::RoleDelete.from_json(data.to_json)
                    call_event guild_role_delete, payload
                when "MESSAGE_CREATE"
                    payload = Channels::Message.from_json(data.to_json)
                    call_event message_create, payload
                when "MESSAGE_UPDATE"
                    payload = Channels::Message.from_json(data.to_json)
                    call_event message_update, payload
                when "MESSAGE_DELETE"
                    payload = Channels::MessageDelete.from_json(data.to_json)
                    call_event message_delete, payload
                when "MESSAGE_DELETE_BULK"
                    payload = Channels::MessageDeleteBulk.from_json(data.to_json)
                    call_event message_delete_bulk, payload
                when "PRESENCE_UPDATE"
                    payload = Users::PresenceUpdate.from_json(data.to_json)
                    call_event presence_update, payload
                when "TYPING_START"
                    payload = Users::TypingStart.from_json(data.to_json)
                    call_event typing_start, payload
                when "USER_SETTINGS_UPDATE"
                    # Something is supposed to happen here
                    # the user settings object isn't documented, skipping
                when "VOICE_STATE_UPDATE"
                    payload = Voice::StateUpdate.from_json(data.to_json)
                    call_event voice_state_update, payload
                when "VOICE_SERVER_UPDATE"
                    payload = Voice::ServerUpdate.from_json(data.to_json)
                    call_event voice_server_update, payload
            end
        end

        def connect
            wsFromClient(false)
            self.run
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
                    # commenting error message out while trying to figure out what's going on
                    #logWarning("Error while calling event {{name}}: #{ex.to_s}")
                end
            end
        end

        event ready, Gateway::Ready
        event resume, Gateway::Resume
        event status_update, Gateway::StatusUpdate
        event channel_create, Channels::Channel
        event channel_update, Channels::Channel
        event guild_create, Guilds::Guild
        event guild_update, Guilds::Guild
        event guild_delete, Guilds::Guild
        event guild_ban_add, Users::User
        event guild_ban_remove, Users::User
        event guild_emojis_update, Guilds::EmojisUpdate
        event guild_integrations_update, Guilds::IntegrationsUpdate
        event guild_member_add, Guilds::GuildMember
        event guild_member_remove, Guilds::MemberRemove
        event guild_member_update, Guilds::MemberUpdate
        event guild_members_chunk, Guilds::MembersChunk
        event guild_role_create, Guilds::RoleCreate
        event guild_role_update, Guilds::RoleUpdate
        event guild_role_delete, Guilds::RoleDelete
        event message_create, Channels::Message
        event message_update, Channels::Message
        event message_delete, Channels::MessageDelete
        event message_delete_bulk, Channels::MessageDeleteBulk
        event presence_update, Users::PresenceUpdate
        event typing_start, Users::TypingStart
        event user_settings_update, Users::SettingsUpdate
        event user_update, Users::User
        event voice_state_update, Voice::StateUpdate
        event voice_server_update, Voice::ServerUpdate
    end
end
