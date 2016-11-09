require "json"

module Users
    class User
        JSON.mapping({
            id: {type: String},
            username: {type: String},
            discriminator: {type: String},
            avatar: {type: String},
            bot: {type: Bool, default: false},
            mfa_enabled: {type: Bool, default: false},
            verified: {type: Bool, default: false},
            email: {type: String, default: ""}
        })
    end

    class PresenceUpdate
        JSON.mapping({
            user: {type: User},
            roles: {type: Array(Role)},
            game: {type: Gateway::Game, nilable: true},
            nick: {type: String},
            guild_id:  {type: String},
            stats: {type: String}
        })
    end

    class TypingStart
        JSON.mapping({
            channel_id: {type: String},
            user_id: {type: String},
            timestamp: {type: Int32}
        })
    end
end