require "json"
require "http"
require "./channels"
require "./guilds"

module Gateway
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

    class Ready
        JSON.mapping({
            v: {type: Int32},
            user: {type: User},
            private_channels: {type: Array(Channels::DMChannel)},
            guilds: {type: Array(Guilds::UnavailableGuild)},
            session_id: {type: String},
            #presences: {type: Array(Presence)},
            #relationships: {type: Array(Friend)},
            _trace: {type: Array(String)}
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

    class Resume
        JSON.mapping({
            token: {type: String},
            sesison_id: {type: String},
            seq: {type: Int32}
        })
    end
    class Game
        JSON.mapping({
            name: {type: String, nilable: true}
        })
    end

    class StatusUpdate
        JSON.mapping({
            idle_since: {type: Int32, nilable: true},
            game: {type: Game, nilable: true}
        })
    end
end